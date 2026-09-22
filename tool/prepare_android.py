from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
android_root = root / 'android'
manifest = android_root / 'app/src/main/AndroidManifest.xml'
gradle = android_root / 'app/build.gradle.kts'

ANDROID = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID)

def a(name):
    return f'{{{ANDROID}}}{name}'


# Add a simple monochrome vector small-icon for Android notifications.
drawable = android_root / 'app/src/main/res/drawable'
drawable.mkdir(parents=True, exist_ok=True)
(drawable / 'ic_stat_recovery.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,2A10,10 0,1 0,12 22A10,10 0,0 0,12 2M11,6H13V11H18V13H13V18H11V13H6V11H11V6Z" />
</vector>
''')

# AndroidManifest additions required by flutter_local_notifications scheduling.
tree = ET.parse(manifest)
xml_root = tree.getroot()
existing_permissions = {x.get(a('name')) for x in xml_root.findall('uses-permission')}
for permission in [
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.SCHEDULE_EXACT_ALARM',
]:
    if permission not in existing_permissions:
        node = ET.Element('uses-permission')
        node.set(a('name'), permission)
        xml_root.insert(0, node)

application = xml_root.find('application')
if application is None:
    raise RuntimeError('AndroidManifest.xml has no <application>')

receiver_names = {x.get(a('name')) for x in application.findall('receiver')}
if 'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver' not in receiver_names:
    receiver = ET.SubElement(application, 'receiver')
    receiver.set(a('exported'), 'false')
    receiver.set(a('name'), 'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver')

if 'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver' not in receiver_names:
    receiver = ET.SubElement(application, 'receiver')
    receiver.set(a('exported'), 'false')
    receiver.set(a('name'), 'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver')
    intent = ET.SubElement(receiver, 'intent-filter')
    for action_name in [
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
        'android.intent.action.QUICKBOOT_POWERON',
        'com.htc.intent.action.QUICKBOOT_POWERON',
    ]:
        action = ET.SubElement(intent, 'action')
        action.set(a('name'), action_name)

tree.write(manifest, encoding='utf-8', xml_declaration=True)

# Enable Java 17 + core-library desugaring.
text = gradle.read_text()
text = text.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
text = text.replace('sourceCompatibility = JavaVersion.VERSION_11', 'sourceCompatibility = JavaVersion.VERSION_17')
text = text.replace('targetCompatibility = JavaVersion.VERSION_11', 'targetCompatibility = JavaVersion.VERSION_17')

if 'isCoreLibraryDesugaringEnabled = true' not in text:
    marker = 'compileOptions {'
    if marker not in text:
        raise RuntimeError('compileOptions block not found in build.gradle.kts')
    text = text.replace(marker, marker + '\n        isCoreLibraryDesugaringEnabled = true', 1)

if 'multiDexEnabled = true' not in text:
    marker = 'defaultConfig {'
    text = text.replace(marker, marker + '\n        multiDexEnabled = true', 1)

if 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' not in text:
    text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'

gradle.write_text(text)
print('Android project patched for scheduled local notifications.')
