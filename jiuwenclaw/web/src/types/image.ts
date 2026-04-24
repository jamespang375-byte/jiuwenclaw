/**
 * 图片附件类型
 */
export interface ImageAttachment {
  file: File;
  preview: string; // data URL (data:image/png;base64,...)
}
