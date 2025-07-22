import router from '@ohos.router'
import prompt from '@system.prompt';
import { ArrayHelper, PermissionHelper } from './util/Utils'
import ProgressDialog from './view/ProgressDialog'
import { GlobalContext } from './util/GlobalContext';
import { Permissions } from '@ohos.abilityAccessCtrl';
import ble from '@ohos.bluetooth.ble';
import access from '@ohos.bluetooth.access';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils'
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import Er1Device from '@lepu/lepuhmble/src/main/ets/device/er1/Er1Device';
import O2Device from '@lepu/lepuhmble/src/main/ets/device/o2/O2Device';
import BleDevice from '@lepu/lepuhmble/src/main/ets/data/BleDevice';
import BleManager from '@lepu/lepuhmble/src/main/ets/BleManager';
import BleScanRuleConfig from '@lepu/lepuhmble/src/main/ets/scan/BleScanRuleConfig';
import BleGattCallback from '@lepu/lepuhmble/src/main/ets/callback/BleGattCallback';
import BleException from '@lepu/lepuhmble/src/main/ets/exception/BleException';
import AdapterManager from '@lepu/lepuhmble/src/main/ets/bluetooth/AdapterManager';
import BleScanCallback from '@lepu/lepuhmble/src/main/ets/callback/BleScanCallback';


@Entry
@Preview
@Component
struct Page {
  @State edit_text_uuid: string = '';
  @State edit_text_name: string = '';
  @State edit_text_mac: string = '';
  @State switch_auto_connect: boolean = false;
  @State setting_visibility: Visibility = Visibility.None;
  @State search_setting_text: Resource = $r('app.string.expand_search_settings');
  @State btn_scan_text: Resource = $r('app.string.start_scan');
  @State btn_log_text: Resource = $r('app.string.log');
  @State is_loading: boolean = false;
  @State loading_rotate: number = 0;
  @State private toast_open_bluetooth: string = '';
  @State private toast_connect_fail: string = '';
  @State private toast_disconnected: string = '';
  @State private toast_active_disconnected: string = '';
  @State bleDeviceList: BleDevice[] = [];
  @State connectedDevices: string[] = [];

  private loadStrings() {
    let manager = (GlobalContext.getContext().getValue('context') as Context).resourceManager;

    manager.getStringValue($r('app.string.please_open_blue').id).then(text => {
      this.toast_open_bluetooth = text;
    })
    manager.getStringValue($r('app.string.connect_fail').id).then(text => {
      this.toast_connect_fail = text;
    })
    manager.getStringValue($r('app.string.disconnected').id).then(text => {
      this.toast_disconnected = text;
    })
    manager.getStringValue($r('app.string.active_disconnected').id).then(text => {
      this.toast_active_disconnected = text;
    })
  }

  build() {
    Column() {
      Row() {
        Button(this.btn_scan_text)
          .onClick(() => this.onSearchClick())
          .fontSize(16)
          .height(40)
          .margin({ right: 50 })
          .fontWeight(FontWeight.Bold)


        LoadingProgress()
          .width(40)
          .height(40)
          .color($r('app.color.colorPrimary'))
          .visibility(this.is_loading ? Visibility.Visible : Visibility.None)

        Button(this.btn_log_text)
          .onClick(() => {
            let file = FileUtils.getNewestFile(`${getContext().getApplicationContext().filesDir}/log`)
            if (file != null) {
              FileUtils.shareFile(getContext(), file.path)
            }
          })
          .fontSize(16)
          .height(40)
          .margin({ left: 50 })
          .fontWeight(FontWeight.Bold)
      }.width('100%').justifyContent(FlexAlign.SpaceAround)


      List() {
        ForEach(this.bleDeviceList, (device: BleDevice) => {
          ListItem() {
            Row() {
              if (this.isConnected(device)) {
                Image($r('app.media.ic_blue_connected')).objectFit(ImageFit.None).width(30).height(30)
                Column() {
                  Text(device.getName()).margin({ bottom: 2 }).fontSize(14).fontColor($r('app.color.colorPrimary'))
                  Text(device.getMac()).margin({ top: 2 }).fontSize(12).fontColor($r('app.color.colorPrimary'))
                }.layoutWeight(1).margin({ left: 10 }).alignItems(HorizontalAlign.Start)

                Row() {
                  Button($r('app.string.disconnect'))
                    .width(100)
                    .height(36)
                    .margin({ left: 5 })
                    .fontSize(12)
                    .onClick(() => this.onDisconnectClick(device))
                  Button($r('app.string.enter'))
                    .width(100)
                    .height(36)
                    .margin({ left: 5 })
                    .fontSize(12)
                    .onClick(() => this.onDetailClick(device))
                }
              } else {
                Image($r('app.media.ic_blue_remote')).objectFit(ImageFit.None).width(30).height(30)
                Column() {
                  Text(device.getName()).margin({ bottom: 2 }).fontSize(14)
                  Text(device.getMac()).margin({ top: 2 }).fontSize(12)
                }.layoutWeight(1).margin({ left: 10 }).alignItems(HorizontalAlign.Start)

                Row() {
                  Text('' + device.getRssi()).fontSize(14)
                  Image($r('app.media.ic_rssi')).objectFit(ImageFit.ScaleDown).width(18).height(18).margin({ left: 5 });
                  Button($r('app.string.connect'))
                    .width(100)
                    .height(36)
                    .margin({ left: 5 })
                    .fontSize(12)
                    .onClick(() => this.onConnectClick(device))
                }
              }
            }.width('100%').height(48)
          }
        }, (item: BleDevice) => item.getMac())
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 10 })
      .padding({ left: 5, right: 5 })
      .divider({ strokeWidth: 0.5, color: '#aaa' })
    }
    .width('100%')
    .height('100%')
  }

  private isConnected(device: BleDevice): boolean {
    return ArrayHelper.contains(this.connectedDevices, device.getMac());
  }

  private onSearchClick(): void {
    if (this.btn_scan_text.id == $r('app.string.start_scan').id) {
      this.checkPermissions();
    } else if (this.btn_scan_text.id == $r('app.string.stop_scan').id) {
      BleManager.getInstance().cancelScan();
    }
  }

  private onConnectClick(device: BleDevice) {
    if (!BleManager.getInstance().isConnected(device)) {
      BleManager.getInstance().cancelScan();
      this.connect(device);
    }
  }

  private onDisconnectClick(device: BleDevice) {
    BleManager.getInstance().disconnect(device);
  }

  private onDetailClick(device: BleDevice) {
    let str = device.getName();
    BleLog.i("onDetailClick deviceName:" + device.getName());
    let page = "";
    if (str.toLowerCase().includes("er1".toLowerCase()) || str.toLowerCase().includes("er2".toLowerCase()) ||
    str.toLowerCase().includes("duoek".toLowerCase())) {
      page = 'pages/device/Er1Page';
    } else if (str.toLowerCase().includes("o2".toLowerCase())
      || str.toLowerCase().includes("oxy".toLowerCase())
      || str.toLowerCase().includes("sleep".toLowerCase())
      || str.toLowerCase().includes("bbsm".toLowerCase())
      || str.toLowerCase().includes("po4".toLowerCase())
      || str.toLowerCase().includes("po6".toLowerCase())) {
      page = 'pages/device/O2Page';
    } else if (str.toLowerCase().includes("bp".toLowerCase())) {
      page = 'pages/device/BpPage';
    }

    if (page) {
      router.pushUrl({ url: page, params: { device: device } });
    } else {
      prompt.showToast({ message: `等待接入。。。`, duration: 300 });
    }
  }

  private checkPermissions(): void {
    let permissions: Permissions[] = ["ohos.permission.ACCESS_BLUETOOTH"];
    PermissionHelper.requestPermissions(permissions, results => {
      for (let i = 0; i < permissions.length; i++) {
        if (results[i] != 0) {
          let msg = "permission " + permissions[i] + " not granted!";
          prompt.showToast({ message: msg, duration: 2000 })
          return;
        }
      }

      let result = access.getState();
      BleLog.i("checkPermissions bluetooth.state: " + result);
      if (result == access.BluetoothState.STATE_OFF) {
        prompt.showToast({ message: this.toast_open_bluetooth, duration: 300, })
        return;
      }

      this.doScan();
    });
  }

  private doScan() {
    this.setScanRule();
    this.startScan();
  }

  private setScanRule(): void {
    let uuids: string[];
    let str_uuid: string = this.edit_text_uuid;
    if (!str_uuid) {
      uuids = [];
    } else {
      uuids = str_uuid.split(",");
    }
    let serviceUuids: string[] = [];
    if (uuids != null && uuids.length > 0) {
      serviceUuids = new Array(uuids.length);
      for (let i = 0; i < uuids.length; i++) {
        let name: string = uuids[i];
        let components: string[] = name.split("-");
        if (components.length != 5) {
          serviceUuids[i] = '';
        } else {
          serviceUuids[i] = uuids[i];
        }
      }
    }

    let names: string[];
    let str_name: string = this.edit_text_name;
    if (!str_name) {
      names = [];
    } else {
      names = str_name.split(",");
    }

    let mac: string = this.edit_text_mac;

    let isAutoConnect: boolean = this.switch_auto_connect;

    let scanRuleConfig: BleScanRuleConfig = BleScanRuleConfig.Builder
      .setServiceUuids(serviceUuids)// 只扫描指定的服务的设备，可选
      .setDeviceName(true, names)// 只扫描指定广播名的设备，可选
      .setDeviceMac(mac)// 只扫描指定mac的设备，可选
      .setAutoConnect(isAutoConnect)// 连接时的autoConnect参数，可选，默认false
      .setScanTimeOut(15000)// 扫描超时时间，可选，默认10秒
      .build();

    BleManager.getInstance().initScanRule(scanRuleConfig);
  }

  public clearConnectedDevice() {
    for (let i = 0; i < this.bleDeviceList.length; i++) {
      let device: BleDevice = this.bleDeviceList[i];
      if (BleManager.getInstance().isConnected(device)) {
        ArrayHelper.removeIndex(this.bleDeviceList, i);
      }
    }
  }

  public clearScanDevice() {
    for (let i = 0; i < this.bleDeviceList.length; i++) {
      let device: BleDevice = this.bleDeviceList[i];
      if (!BleManager.getInstance().isConnected(device)) {
        ArrayHelper.removeIndex(this.bleDeviceList, i);
      }
    }
  }

  public clear() {
    this.bleDeviceList = [];
  }

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

  private progressDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: ProgressDialog()
  });

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

  //组件即将显示时调用
  aboutToAppear() {
    BleManager.getInstance().init();
    BleManager.getInstance()
      .enableLog(true)
      .setReConnectCount(3, 5000)
      .setConnectOverTime(20000);

    this.loadStrings();
    AdapterManager.openBluetooth();
  }

  aboutToDisappear() {
    BleManager.getInstance().disconnectAllDevice();
    BleManager.getInstance().destroy();
  }
}






