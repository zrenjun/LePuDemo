# LePuHmBle

## 简介

LePuHmBle是一个基于鸿蒙5.0处理乐普BLE蓝牙设备的库。


## 下载安装

```shell
ohpm install @lepu/lepuhmble 
```

## 使用说明（详细请参考demo）

1. 初始化

```
BleManager.getInstance().init();
```

2. 初始化配置

```
BleManager.getInstance()
            .enableLog(true)
            .setReConnectCount(1, 5000)
            .setConnectOverTime(20000);
```

3. 配置扫描规则

```
let scanRuleConfig: BleScanRuleConfig = new BleScanRuleConfig.Builder()
              .setServiceUuids(serviceUuids)      // 只扫描指定的服务的设备，可选
              .setDeviceName(true, names)         // 只扫描指定广播名的设备，可选
              .setDeviceMac(mac)                  // 只扫描指定mac的设备，可选
              .setAutoConnect(isAutoConnect)      // 连接时的autoConnect参数，可选，默认false
              .setScanTimeOut(10000)              // 扫描超时时间，可选，默认10秒
              .build();
BleManager.getInstance().initScanRule(scanRuleConfig);
```

4. 扫描设备

```
  private startScan(): void {
    let _this = this;
    BleLog.i("startScan");

    class TempBleScanCallback extends BleScanCallback {
      onScanStarted(success: boolean): void {
        BleLog.i("onScanStarted success:" + success);
        _this.clearScanDevice();
        _this.is_loading = true;
        _this.loading_rotate = 360;
        _this.btn_scan_text = $r('app.string.stop_scan');

      }

      onLeScan(_bleDevice: BleDevice): void {
      }

      onScanning(bleDevice: BleDevice): void {
        if (bleDevice.mDeviceName.toString().length > 0) {
          ArrayHelper.add(_this.bleDeviceList, bleDevice);
          _this.bleDeviceList.sort((a, b) => b.mRssi - a.mRssi);
        }
      }

      onScanFinished(_scanResultList: Array<BleDevice>): void {
        BleLog.i("onScanFinished");
        _this.is_loading = false;
        _this.loading_rotate = 0;
        _this.btn_scan_text = $r('app.string.start_scan');
      }
    }

    BleManager.getInstance().scan(new TempBleScanCallback());
  }

```

5. 连接设备

```
  private connect(bleDevice: BleDevice): void {
    let _this = this;

    class IndexBleGattCallback extends BleGattCallback {
      public onStartConnect(): void {
        _this.progressDialogCtrl.open();
      }

      public onConnectFail(_bleDevice: BleDevice, _exception: BleException): void {
        _this.progressDialogCtrl.close();
        prompt.showToast({ message: _this.toast_connect_fail, duration: 300, });
        _this.connect(_bleDevice);
      }

      public onConnectSuccess(bleDevice: BleDevice, _gatt: ble.GattClientDevice, _status: number): void {
        _this.progressDialogCtrl.close();
        ArrayHelper.add(_this.connectedDevices, bleDevice.getMac());
        BleLog.e(_this.connectedDevices.join(";") + "  连接成功")
        // init device
        let str = bleDevice.getName();
        if (str.toLowerCase().includes("er1")||str.toLowerCase().includes("er2") || str.toLowerCase().includes("duoek")) {
          Er1Device.getInstance().init(bleDevice);
        } else if (str.toLowerCase().includes("o2".toLowerCase())
          || str.toLowerCase().includes("oxy".toLowerCase())
          || str.toLowerCase().includes("sleep".toLowerCase())
          || str.toLowerCase().includes("bbsm".toLowerCase())
          || str.toLowerCase().includes("po4".toLowerCase())
          || str.toLowerCase().includes("po6".toLowerCase())) {
          O2Device.getInstance().init(bleDevice);
        }
      }

      public onDisConnected(isActiveDisConnected: boolean, _device: BleDevice, _gatt: ble.GattClientDevice,
        _status: number): void {
        _this.progressDialogCtrl.close();
        ArrayHelper.remove(_this.connectedDevices, bleDevice.getMac());
        if (_this.connectedDevices.length > 0) {
          BleLog.e(_this.connectedDevices.join(";"))
        } else {
          BleLog.e("没有设备连接了")
        }
        if (isActiveDisConnected) {
          // 主动断开
          prompt.showToast({ message: _this.toast_active_disconnected, duration: 300 });
        } else {
          prompt.showToast({ message: _this.toast_disconnected, duration: 300 });
          _this.connect(_device);
        }
      }
    }

    BleManager.getInstance().connect(bleDevice, new IndexBleGattCallback());
  }
```

6. 取消扫描

```
  BleManager.getInstance().cancelScan();
```
7. 设备连接后初始化（需要使用对应设备的 类）

```
  Device.getInstance().init(bleDevice);
```

8. 发送命令

```
  Device.getInstance().setTime();
```

9. 接收返回数据

```
  emitter.on(eventId, (eventData: emitter.EventData) => {
     prompt.showToast({ message: "设置时间成功", duration: 300 });
  });   
```

## 设备说明

1. ER1系列（包含ER1、ER2、DUOEK等设备）

```
  使用Er1Device可以获取指令及发送命令，文件滤波算法需要分段滤波
```
2. O2系列（包含O2、OXY、SLEEP、BBSM等设备）

```
  使用O2Device可以获取指令及发送命令，参数设置参考设置时间
```
