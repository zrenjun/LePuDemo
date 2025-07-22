import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { GlobalContext } from '../pages/util/GlobalContext';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';


export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    BleLog.init(this.context);
    BleLog.i( 'Ability onCreate');
    GlobalContext.getContext().setValue('context',this.context);
    GlobalContext.getContext().setValue('abilityWant',want);
  }

  onDestroy(): void {
    BleLog.i( 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 主窗口创建后，设置主页面
    BleLog.i('Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        BleLog.i('Failed to load the content. Cause: '+ JSON.stringify(err));
        return;
      }
      BleLog.i( 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // 主窗口被销毁，释放 UI 相关资源
    BleLog.i( 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    BleLog.i( 'Ability onForeground');
  }

  onBackground(): void {
    BleLog.i( 'Ability onBackground');
  }
}