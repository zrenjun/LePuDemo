import { prompt, router } from '@kit.ArkUI';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import ProgressDialog from './view/ProgressDialog';
import Bp2BpFile from '@lepu/lepuhmble/src/main/ets/device/bp/Bp2BpFile';
import Bp2EcgFile from '@lepu/lepuhmble/src/main/ets/device/bp/Bp2EcgFile';
import Bp2UserList from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3UserList';
import Bp3BpList from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3BpList';
import Bp3EcgList from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3EcgList';
import Bp3EcgFile from '@lepu/lepuhmble/src/main/ets/device/bp/Bp3EcgFile';
import PpgFile from '@lepu/lepuhmble/src/main/ets/device/bp/PpgFile';
import { EcgData } from './EcgFileViewPage';
import { EcgDetailWaveView } from './view/EcgDetailWaveView';
import { EcgFilter } from '@lepu/lepuhmble';
import { PxUtils } from './util/Utils';

@Entry
@Component
struct BpFileViewPage {
  @State private rawData: Bp2BpFile | undefined = undefined;
  @State private userList: Bp2UserList | undefined = undefined;
  @State private bpList: Bp3BpList | undefined = undefined;
  @State private ecgList: Bp3EcgList | undefined = undefined;
  @State private ecgFile: Bp3EcgFile | undefined = undefined;
  @State private ppg: PpgFile | undefined = undefined;
  @State private ecgDataList: EcgData[] = [];
  private sampling: number = 125;
  private speed: number = 6.25;
  private waveScale: number = 1.0;
  private dataLine: number = 0;

  build() {
    Column() {
      Text('文件详情')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)

      Scroll() {
        Column() {
          Text(JSON.stringify(this.rawData))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
          Text(JSON.stringify(this.userList))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
          Text(JSON.stringify(this.bpList))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
          Text(JSON.stringify(this.ecgList))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
          Text(JSON.stringify(this.ecgFile))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
          Text(JSON.stringify(this.ppg))
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
        }
      }.padding(20)

      List() {
        ForEach(this.ecgDataList, (ecgData: EcgData) => {
          ListItem() {
            EcgDetailWaveView({
              timeTemp: ecgData.time,
              waveData: ecgData.data,
              samplingRate: this.sampling,
              waveScale: this.waveScale,
              speed: this.speed
            })
          }
        }, (ecgData: EcgData) => `${ecgData.time}`)
      }
      .edgeEffect(EdgeEffect.None) // 禁用默认滑动效果
    }
    .height('100%')
    .width('100%')
  }

  private progressDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: ProgressDialog()
  });

  aboutToAppear() {
    this.progressDialogCtrl.open();
    const params = router.getParams() as Record<string, string>;
    const path = params['path'];
    const fileName = params['name'];
    const deviceName = params['deviceName']; // 设备名称

    BleLog.e(`path : ${path}`);
    BleLog.e(`deviceName : ${deviceName}`);
    if (!path || !FileUtils.accessSync(path)) {
      prompt.showToast({ message: `文件不存在`, duration: 300 });
      this.progressDialogCtrl.close();
      return;
    }

    //bp3

    // user.list：用户列表文件

    // bp.list: 测量血压记录列表
        //解析bp.list   BP+其中fileName可以下载波形文件 PpgFile
        // BPyyMMddhhmmss：血压波形文件，文件名为记录开始测量时间。如：“BP180601114631”表示开始测量时间为2018-06-01 11:46:31。

    // ecg.list: 测量心电记录列表
         //解析ecg.list   其中fileName可以下载波形文件   Bp3EcgFile
         // yyyyMMddhhmmss：心电波形文件，文 件名为记录开始测量时间。如：“20180601114631”表示开始测量时间为2018-06-01 11:46:31。

    //bp2
    // 20220315202609

    //     TYPE_BP = 0x01,    // 血压测量文件，当前BP2设备使用
    //     TYPE_ECG_SINGLE = 0x02,    // 单导心电文件，BP2设备使用
    //     TYPE_BP_RAW = 0x05,    // 血压波形文件，BP2设备与桌面血压计使用
    //     TYPE_USER = 0x06,    // 用户列表，BP2 wifi，桌面血压计
    //     TYPE_PPG = 0x07,     // ppg原始文


    FileUtils.readStream(path).then((data) => {
      const fileType = data[1];

      if (fileName.endsWith('list')) {
        switch (fileType) {
          case 1:
            this.bpList = new Bp3BpList(data);
            break;
          case 2:
            this.ecgList = new Bp3EcgList(data);
            break;
          case 0: //bp2w
          case 6:
            this.userList = new Bp2UserList(data);
            break;
        }
      } else {
        if (deviceName.toLowerCase().includes("bp3")) {
          switch (fileType) {
            case 2:
              this.ecgFile = new Bp3EcgFile(data);
              break;
            case 5:
            case 7:
              this.ppg = new PpgFile(data);
              break;
          }
        } else {
          if (fileType == 1) {
            this.rawData = new Bp2BpFile(data);
          } else if (fileType == 2){
            this.dataLine = PxUtils.getLineSize(this.sampling, this.speed);
            EcgFilter.resetFilter();
            const rawData2 = new Bp2EcgFile(data);
            const len = rawData2.waveShort.length;
            const newData: EcgData[] = [];
            for (let i = 0; i < len; i += this.dataLine) {
              newData.push(new EcgData(rawData2.measureTime * 1000 + Math.round((i / this.sampling) * 1000),
                rawData2.waveShort.subarray(i, i + this.dataLine), 0.003098));
            }
            this.ecgDataList = this.ecgDataList.concat(newData);
          }
        }
      }

      this.progressDialogCtrl.close();
    });
  }
}