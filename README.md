# Dotfile Installer For Arch Linux

## Bluetooth Conf

```
# bluetoothctl
[bluetoothctl] # default-agent
[bluetoothctl] # power on
[bluetoothctl] # scan on
[bluetoothctl] # pair 88:D0:39:6C:A5:0E
[bluetoothctl] # trust 88:D0:39:6C:A5:0E
[bluetoothctl] # connect 88:D0:39:6C:A5:0E
```

### Discoverable on startup

```
/etc/bluetooth/main.conf
------------------------
[General]
DiscoverableTimeout = 0
Discoverable=true
```

### PulseAudio

```
/etc/pulse/system.pa
--------------------
load-module module-bluetooth-policy
load-module module-bluetooth-discover
```

```
/etc/pulse/default.pa
------------------------------------
load-module module-switch-on-connect
```
