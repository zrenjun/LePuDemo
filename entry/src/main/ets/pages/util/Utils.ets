import { GlobalContext } from './GlobalContext';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import BleLog from '@lepu/lepuhmble/src/main/ets/utils/BleLog';
import { display } from '@kit.ArkUI';

export class ArrayHelper {
  public static add<T>(array: Array<T>, elem: T) {
    array.push(elem);
  }

  public static contains<T>(array: Array<T>, elem: T): boolean {
    return array.indexOf(elem) >= 0;
  }

  public static remove<T>(array: Array<T>, elem: T) {
    let index = array.indexOf(elem);
    if (index >= 0) {
      array.splice(index)
    }
  }

  public static removeIndex<T>(array: Array<T>, index: number) {
    if (index >= 0 && index < array.length) {
      array.splice(index, 1);
    }
  }
}


export class PermissionHelper {
  public static checkPermissions(permissions: Permissions[], callback: (results: number[]) => void) {
    let context: ESObject = GlobalContext.getContext().getValue('context');
    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(context, permissions, (err: BusinessError, results: PermissionRequestResult) => {
        callback(results.authResults)
      });
  }

  public static requestPermissions(permissions: Permissions[], callback: (results: number[]) => void) {
    let context = GlobalContext.getContext().getValue('context') as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions, (err: BusinessError, results: PermissionRequestResult) => {
      BleLog.i("requestPermissionsFromUser result: " + JSON.stringify(results))
      callback(results.authResults);
    });
  }
}

export class TextUtils {
  public static isEmpty(text: string) {
    return text == null || text == undefined || text.length == 0;
  }
}


export class PxUtils {
  /**
   * 计算屏幕像素密度与屏幕宽度毫米数的比值
   * 通过获取设备的显示信息，计算出屏幕像素密度与实际物理尺寸的比例关系
   * @returns 屏幕像素密度与屏幕宽度毫米数的比值
   */
  public static getPingMuSize(): number {
    const mm: number = 25.4; //1英寸 = 25.4毫米
    // 获取默认显示器的同步信息
    let displayInfo = display.getDefaultDisplaySync();
    // 获取 x 轴 DPI
    let xdpi: number = displayInfo.xDPI;
    // BleLog.e("xdpi: " + xdpi);
    let width: number = displayInfo.width;
    // BleLog.e("width: " + width);
    // let densityDPI: number = displayInfo.densityDPI;
    // BleLog.e("densityDPI: " + densityDPI);
    // let densityPixels: number = displayInfo.densityPixels;
    // BleLog.e("densityPixels: " + densityPixels);
    //   xdpi: 393.3370056152344
    //   width: 1084
    // 根据设置变化  densityDPI/densityPixels = 160 保持不变
    //   densityDPI: 480  ==》408
    //   densityPixels: 3  == 》2.55


    // 计算屏幕宽度对应的毫米数
    let widthMm: number = (width / xdpi) * mm; // 1084/393.3370056152344 = 2.756 * 25.4 = 70
    return parseFloat((xdpi / widthMm).toFixed(2));  //5.62   ToDo
  }

  /**
   * 计算屏幕每一行需要画图点数
   * @param samplingRate 采样率
   * @param speed 速度
   * @returns 采样点数
   */
  public static getLineSize(samplingRate: number, speed: number): number {
    let sec = speed * PxUtils.getPingMuSize();  // 每秒画多少个点
    let displayInfo = display.getDefaultDisplaySync();
    let xdpi: number = displayInfo.xDPI;
    return parseInt(((xdpi / sec) * samplingRate).toFixed(0));  //一行秒数*采样
  }
  /**
   * 计算屏幕每一行需要画图点数
   * @param samplingRate 采样率
   * @param speed 速度
   * @returns 采样点数
   */
  public static getXNv(lineSize: number): number {
    let displayInfo = display.getDefaultDisplaySync();
    let xdpi: number = displayInfo.xDPI;
    return parseFloat((xdpi / lineSize).toFixed(2));  //2点之间间隔
  }
}

export class TimeUtils {
  public static  convertToTimestamp(dateStr: string): number {
    const year = parseInt(dateStr.substring(0, 4));
    const month = parseInt(dateStr.substring(4, 6)) - 1;
    const day = parseInt(dateStr.substring(6, 8));
    const hours = parseInt(dateStr.substring(8, 10));
    const minutes = parseInt(dateStr.substring(10, 12));
    const seconds = parseInt(dateStr.substring(12, 14));
    const date = new Date(year, month, day, hours, minutes, seconds);
    return date.getTime();
  }

  public static convertToDateStr(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const seconds = date.getSeconds();
    return `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')} ${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }
}
