import worker from '@ohos.worker';
import { logHandler, logErrorHandler } from '@ohos-port/xlog/XLogBaseWorker'

worker.workerPort.onmessage = logHandler;
worker.workerPort.onerror = logErrorHandler;