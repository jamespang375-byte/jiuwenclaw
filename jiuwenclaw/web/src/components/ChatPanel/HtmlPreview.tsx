/**
 * HtmlPreview 组件
 *
 * 在聊天消息中内嵌预览 HTML 文件（如技能生成的地图、报表）
 */

import { useState, useCallback } from 'react';
import clsx from 'clsx';

interface HtmlPreviewProps {
  url: string;
  title?: string;
}

export function HtmlPreview({ url, title }: HtmlPreviewProps) {
  const [isOpen, setIsOpen] = useState(false);

  const toggle = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  const displayTitle = title || 'HTML 预览';

  return (
    <div className="html-preview-container my-2 rounded-lg border border-border overflow-hidden bg-white">
      {/* 标题栏 */}
      <button
        onClick={toggle}
        className={clsx(
          'w-full flex items-center justify-between px-3 py-2 text-sm transition-colors',
          'hover:bg-secondary/50 bg-secondary/30'
        )}
      >
        <div className="flex items-center gap-2">
          {/* 网页图标 */}
          <svg className="w-4 h-4 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A11.959 11.959 0 013.598 14.25M3.598 14.25A8.959 8.959 0 013 12c0-.778.099-1.533.284-2.253" />
          </svg>
          <span className="font-medium text-text-primary">{displayTitle}</span>
          <span className="text-xs text-text-muted truncate max-w-[200px]">{url}</span>
        </div>
        <div className="flex items-center gap-1">
          {isOpen && (
            <a
              href={url}
              target="_blank"
              rel="noopener noreferrer"
              onClick={(e) => e.stopPropagation()}
              className="px-2 py-0.5 text-xs rounded bg-accent text-white hover:bg-accent/90 transition-colors"
              title="在新标签页打开"
            >
              打开
            </a>
          )}
          <svg
            className={clsx('w-4 h-4 text-text-muted transition-transform', isOpen && 'rotate-180')}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
          </svg>
        </div>
      </button>

      {/* iframe 预览区 */}
      {isOpen && (
        <div className="w-full" style={{ height: '360px' }}>
          <iframe
            src={url}
            title={displayTitle}
            className="w-full h-full border-0"
            sandbox="allow-scripts allow-same-origin allow-popups"
            loading="lazy"
          />
        </div>
      )}
    </div>
  );
}

/**
 * 从 Markdown 内容中提取 HTML 文件链接
 * 返回 {url, title} 数组
 */
export function extractHtmlLinks(content: string): Array<{ url: string; title: string }> {
  const results: Array<{ url: string; title: string }> = [];
  const seen = new Set<string>();

  // 匹配 Markdown 链接: [text](url)
  const mdLinkRegex = /\[([^\]]+)\]\(([^)]+\.html(?:\?[^)]*)?)\)/gi;
  let match: RegExpExecArray | null;
  while ((match = mdLinkRegex.exec(content)) !== null) {
    const title = match[1].trim();
    const url = match[2].trim();
    if (!seen.has(url)) {
      seen.add(url);
      results.push({ url, title });
    }
  }

  // 匹配裸 URL (http://.../something.html)
  const bareUrlRegex = /(https?:\/\/[^\s<>"]+\.html(?:\?[^\s<>"]*)?)/gi;
  while ((match = bareUrlRegex.exec(content)) !== null) {
    const url = match[1].trim();
    if (!seen.has(url)) {
      seen.add(url);
      results.push({ url, title: 'HTML 预览' });
    }
  }

  return results;
}
