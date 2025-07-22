import { prompt, router } from '@kit.ArkUI';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import FileUtils from '@lepu/lepuhmble/src/main/ets/utils/FileUtils';
import ProgressDialog from './view/ProgressDialog';
import O2File from '@lepu/lepuhmble/src/main/ets/device/o2/O2File';
import BBSMS3File from '@lepu/lepuhmble/src/main/ets/device/o2/BBSMS3File';

@Entry
@Component
struct Spo2FileViewPage {
  @State private rawData: O2File | undefined = undefined;
  @State private rawData2: BBSMS3File | undefined = undefined;

  build() {
    Column() {
      Text('文件详情')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .height(36)

      Scroll() {
        Text(JSON.stringify(this.rawData))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
      }.padding(20)

      Scroll() {
        Text(JSON.stringify(this.rawData2))
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
      }.padding(20)
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
    const deviceName = params['deviceName']; // 设备名称

    BleLog.e(`path : ${path}`);
    BleLog.e(`deviceName : ${deviceName}`);
    if (!path || !FileUtils.accessSync(path)) {
      prompt.showToast({ message: `文件不存在`, duration: 300 });
      this.progressDialogCtrl.close();
      return;
    }

    FileUtils.readStream(path).then((data) => {
      if (deviceName.includes("S3")) {
        this.rawData2 = new BBSMS3File(data);
      }else {
        this.rawData = new O2File(data);
      }
      this.progressDialogCtrl.close();
    });
  }
}