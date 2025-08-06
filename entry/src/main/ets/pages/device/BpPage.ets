import { prompt, router } from '@kit.ArkUI';
import BpDevice from '@lepu/lepuhmble/src/main/ets/device/bp/BpDevice';
import { emitter } from '@kit.BasicServicesKit';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import DeviceInfo from '@lepu/lepuhmble/src/main/ets/device/DeviceInfo';
import BpConfig from '@lepu/lepuhmble/src/main/ets/device/bp/BpConfig';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import FileTransmit from '@lepu/lepuhmble/src/main/ets/device/FileTransmit';
import BpRtData from '@lepu/lepuhmble/src/main/ets/device/bp/BpRtData';
import { ECGWaveform } from '../view/EcgRtWaveView';
import BleDevice from '@lepu/lepuhmble/src/main/ets/data/BleDevice';
import EcgFilter from '@lepu/lepuhmble/src/main/ets/utils/EcgFilter';
import Bp2WifiConfig from '@lepu/lepuhmble/src/main/ets/device/bp/BpWifiConfig';
import Bp3UserList from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3UserList';
import Bp3UserInfo from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3UserInfo';
import BpNameToIcon from '@lepu/lepuhmble/src/main/ets/device/bp/BpNameToIcon';


@Entry
@Component
struct BpPage {
  private device: BleDevice | undefined = undefined;
  private sampling: string = "125";
  @State flag: boolean = true;
  @State files: string[] = [];
  @State fileTransmit: FileTransmit[] = [];
  @State deviceInfo: DeviceInfo | undefined = undefined;
  @State deviceConfig: BpConfig | undefined = undefined;
  @State wifiConfig: Bp2WifiConfig | undefined = undefined;
  @State bpData: BpRtData | undefined = undefined;

  private getProgress(file: string): number {
    const status = this.fileTransmit.find((item) => item.fileName === file);
    if (status == undefined || status.cancel) {
      return 0;
    }
    return status.offset * 100 / status.fileSize;
  }

  private toggleRealTimeData() {
    if (this.flag) {
      BpDevice.getInstance().getRealTimeData();
    } else {
      BpDevice.getInstance().stopRealTimeData();
    }
    this.flag = !this.flag;
  }

  build() {
    Column() {
      Text('设置时间')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().setTime();
        })
      Text('获取设备信息')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().getDeviceInfo();
        })
      if (this.deviceInfo) {
        Text(JSON.stringify(this.deviceInfo))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(100)
      }
      Text('获取配置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().getConfig();
        })
      if (this.deviceConfig) {
        Text(JSON.stringify(this.deviceConfig))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(100)
        Text("设置配置")
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(36)
          .onClick(() => {
            if (this.deviceConfig) {
              this.deviceConfig.beepSwitch = !this.deviceConfig.beepSwitch;
              BpDevice.getInstance().setConfig(this.deviceConfig);
            }
          })
      }
      //wifi 版  bpw bp3
      Text('获取WiFi配置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().getWiFiConfig();
        })
      if (this.wifiConfig) {
        Text(JSON.stringify(this.wifiConfig))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(150)
        Text("设置WiFi配置")
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(36)
          .onClick(() => {
            if (this.wifiConfig) {
              BpDevice.getInstance().setWiFiConfig(this.wifiConfig);
            }
          })
      }
      Text('恢复出厂设置')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().resetFactory();
        })

      Text('设置用户')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          this.asyncUser();
        })

      Text(this.flag ? '获取实时数据' : '停止获取实时数据')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          this.toggleRealTimeData();
        })

      if (!this.flag) {
        // 插入心电图组件
        ECGWaveform({ samplingRate: this.device?.mDeviceName.toLowerCase().includes("bp3".toLowerCase()) ? 125 : 250 })
          .width('100%')
          .height(200)

        Text(JSON.stringify(this.bpData?.param))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .height(100)
      }

      Text('获取文件列表')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)
        .onClick(() => {
          BpDevice.getInstance().getFileList();
        })

      List() {
        ForEach(this.files, (fileName: string) => {
          ListItem() {
            Row() {
              Text(fileName)
                .fontSize($r('app.float.page_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .margin({ left: 16 })
                .width('45%')

              if (this.getProgress(fileName) == 0) {
                Button('下载')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    BpDevice.getInstance().getFileStart(fileName);
                  }).height(36)
              } else if (this.getProgress(fileName) == 100) {
                Button('查看')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    this.ecgView(fileName);
                  })
                  .height(36)
              } else {
                Button('取消下载')
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    BpDevice.getInstance().getFileStop();
                  }).height(36)

                Text(`${this.getProgress(fileName).toFixed(2)}%`)
                  .fontSize($r('app.float.page_text_font_size'))
                  .fontWeight(FontWeight.Bold)
                  .margin({ left: 16 })
              }
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
          }
        }, (file: string) => file)
      }.width('100%')
      .layoutWeight(1)
      .margin(10)
      .divider({ color: Color.Gray, strokeWidth: 0.5 })
    }
    .height('100%')
    .width('100%')
  }

  private ecgView(fileName: string) {
    router.pushUrl({
      url: 'pages/BpFileViewPage',
      params: {
        path: FileUtils.getFilesDirPath(`${getContext().filesDir}/bp`, `${fileName}`),
        name: fileName,
        deviceName: this.device?.mDeviceName,
        sampling: this.sampling
      }
    });
  }

  private async asyncUser() {
    const users = new Bp3UserList();
    const user = new Bp3UserInfo();
    user.aid = 1;
    user.uid = 18;
    user.fName = "周";
    user.name = "仁军";
    user.gender = 1;
    user.birthday = "2023-01-01";
    user.height = 180;
    user.weight = 80;
    const convertor = new BpNameToIcon();
    const icon = await convertor.createIcon("周仁军");
    user.icon = icon;
    users.userList.push(user);
    BpDevice.getInstance().setFileStart('user.list', Bp3UserList.getDataBytes(users));
  }

  aboutToAppear() {
    this.device = BleDevice.copy((router.getParams() as Record<string, BleDevice>)['device']);
    //订阅事件
    emitter.on(BpDevice.EVENT_SET_TIME, () => {
      prompt.showToast({ message: "设置时间成功", duration: 300 });
    });

    emitter.on(BpDevice.EVENT_GET_INFO, (eventData: emitter.EventData) => {
      this.deviceInfo = eventData.data?.info;
    });


    emitter.on(BpDevice.EVENT_GET_FILE_LIST, (eventData: emitter.EventData) => {
      const files: string[] = eventData.data?.fileList;
      if (files.length > 0) {
        this.files = files;
      } else {
        prompt.showToast({ message: "无历史数据", duration: 300 });
      }
    });
    emitter.on(BpDevice.EVENT_FILE_PROGRESS, (eventData: emitter.EventData) => {
      const item: FileTransmit = eventData.data?.fileStatus;
      const index = this.fileTransmit.findIndex((file) => file.fileName === item.fileName);
      if (index !== -1) {
        // 创建新数组并替换旧对象
        const newFileStatus = this.fileTransmit;
        newFileStatus[index] = item;
        this.fileTransmit = newFileStatus;
      } else {
        this.fileTransmit.push(item);
      }
    });
    emitter.on(BpDevice.EVENT_FILE_END, (eventData: emitter.EventData) => {
      BleLog.i(JSON.stringify(eventData.data?.path));
    });
    emitter.on(BpDevice.EVENT_FILE_END_SET, (eventData: emitter.EventData) => {
      prompt.showToast({ message: "设置用户成功", duration: 300 });
    });


    emitter.on(BpDevice.EVENT_RESET, () => {
      prompt.showToast({ message: "恢复出厂成功", duration: 300 });
    });

    emitter.on(BpDevice.EVENT_GET_CONFIG, (eventData: emitter.EventData) => {
      this.deviceConfig = eventData.data?.config;
    });
    emitter.on(BpDevice.EVENT_SET_CONFIG, () => {
      prompt.showToast({ message: "设置config成功", duration: 300 });
    });

    emitter.on(BpDevice.EVENT_GET_WIFI_CONFIG, (eventData: emitter.EventData) => {
      this.wifiConfig = eventData.data?.wiFiConfig;
    });
    emitter.on(BpDevice.EVENT_SET_WIFI_CONFIG, () => {
      prompt.showToast({ message: "设置 wifi config成功", duration: 300 });
    });

    emitter.on(BpDevice.EVENT_GET_RT_DATA, (eventData: emitter.EventData) => {
      const bpData: BpRtData = eventData.data?.rtData;
      this.bpData = bpData;
      if (bpData.wave.dataType == 2) {
        let dataFilter: number[] = [];
        bpData.wave.wFs.forEach((value) => {
          const filter = EcgFilter.filter(value);
          if (filter.length > 0) {
            dataFilter = dataFilter.concat(filter)
          }
        })
        if (dataFilter.length > 0) { //128
          emitter.emit(ECGWaveform.EVENT_WAVE_DATA, { data: { wave: dataFilter } })
        }
      }
    });
  }

  aboutToDisappear() {
    // 取消事件。
    emitter.off(BpDevice.EVENT_SET_TIME);
    emitter.off(BpDevice.EVENT_GET_INFO);

    emitter.off(BpDevice.EVENT_GET_FILE_LIST);
    emitter.off(BpDevice.EVENT_FILE_PROGRESS);
    emitter.off(BpDevice.EVENT_FILE_END);
    emitter.off(BpDevice.EVENT_FILE_END_SET);
    emitter.off(BpDevice.EVENT_RESET);
    emitter.off(BpDevice.EVENT_GET_CONFIG);
    emitter.off(BpDevice.EVENT_SET_CONFIG);
    emitter.off(BpDevice.EVENT_GET_WIFI_CONFIG);
    emitter.off(BpDevice.EVENT_SET_WIFI_CONFIG);

    emitter.off(BpDevice.EVENT_GET_RT_DATA);

    BpDevice.getInstance().stopRealTimeData();
  }


}


