function export_axes_uniform_pdf(axList, outDir, fileNames, varargin)
% =========================================================================
% export_axes_uniform_pdf - 将多个子图导出为统一画布大小的PDF（用于LaTeX拼版对齐）
% =========================================================================
%
% 功能描述：
%   - 将多个axes导出为具有相同页面尺寸、相同plot box位置和相同白边的PDF文件
%   - 适合在LaTeX中使用minipage进行多图对齐排版
%   - 解决MATLAB紧裁剪导出导致的子图边界不一致问题
%   - 若子图包含 colorbar/legend，本函数会尝试一并复制并保持导出结果一致
%
% 输入：
%   axList    : axes句柄向量，例如 [ax1 ax2 ax3 ax4]
%   outDir    : 输出文件夹路径（字符向量），若不存在会自动创建
%   fileNames : 字符串元胞数组，与axList长度相同，例如 {'a','b','c','d'}（无扩展名）
%
%   可选参数（名值对）：
%   'ExtraPaddingInches' : [L B R T] 在max(TightInset)基础上额外添加的内边距
%                          默认 = [0.10 0.22 0.10 0.25]（更保守，避免大字号 xlabel 被裁剪）
%   'UseLoose'           : true/false, 是否使用 -loose 选项，默认 true
%   'Renderer'           : 'painters' (默认，矢量) 或 'opengl'（位图）
%   'IncludeColorbar'    : true/false, 是否复制与axes关联的colorbar（若存在），默认 true
%
% 输出：
%   无显式返回值；在指定目录生成 n 个 PDF 文件
%
% 使用示例：
%   drawnow;   % 确保布局完成
%   axList = [ax1, ax2, ax3, ax4];
%   fileNames = {'subplot_a', 'subplot_b', 'subplot_c', 'subplot_d'};
%   export_axes_uniform_pdf(axList, 'output_pdfs', fileNames);
%
%   % 带可选参数
%   export_axes_uniform_pdf(axList, 'output_pdfs', fileNames, ...
%       'ExtraPaddingInches', [0.08 0.08 0.08 0.18], 'UseLoose', true);
%
% 依赖函数/工具箱：
%   无
%
% 注意事项：
%   - R2019a 兼容性：使用 inputParser 处理可选参数，不使用 arguments 块
%   - 调用前必须执行 drawnow 确保 MATLAB 已完成布局计算
%   - 假设所有输入axes的plot box尺寸一致（否则以第一个为准）
%   - 本文件包含 0 个辅助函数
%
% =========================================================================

%% 解析可选输入参数
p = inputParser;
addParameter(p, 'ExtraPaddingInches', [0.10 0.22 0.10 0.25]);
addParameter(p, 'UseLoose', true, @islogical);
addParameter(p, 'Renderer', 'painters', @(s) ischar(s) || isstring(s));
addParameter(p, 'IncludeColorbar', true, @islogical);
parse(p, varargin{:});

pad = p.Results.ExtraPaddingInches;
% 若用户只输入单个数值，扩展为四元素向量
if isscalar(pad)
    pad = pad * [1 1 1 1];
end
useLoose = p.Results.UseLoose;
renderer = char(p.Results.Renderer);
includeColorbar = p.Results.IncludeColorbar;

%% 输入检查
% 确保 axList 为列向量
axList = axList(:);
n = numel(axList);

% 检查 fileNames 长度是否与 axList 一致
if numel(fileNames) ~= n
    error('fileNames length (%d) must match axList length (%d).', numel(fileNames), n);
end

% 检查 axes 句柄有效性
for i = 1:n
    if ~isvalid(axList(i)) || ~isgraphics(axList(i), 'axes')
        error('axList(%d) is not a valid axes handle.', i);
    end
end

%% 创建输出目录
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% 确保布局已完成
% 调用 drawnow 强制 MATLAB 完成所有绑定的渲染和布局计算
% 否则 TightInset 可能还是旧值
drawnow;

%% 测量每个axes的TightInset和plot box尺寸
% 使用 inches 单位，便于后续设置 PaperSize/PaperPosition
ti = zeros(n, 4);   % 存储 [Left Bottom Right Top] 边距
pos = zeros(n, 4);  % 存储 [x y width height] plot box 位置
cbGap = zeros(n, 1);   % colorbar 与 plot box 的间距（inches，仅支持左右布局时使用）
cbWidth = zeros(n, 1); % colorbar 宽度（inches，仅支持左右布局时使用）
cbSideFlag = zeros(n, 1); % 1=right, -1=left, 0=none/unknown
cbHandleList = gobjects(n, 1);

for i = 1:n
    ax = axList(i);
    
    % 保存原有单位设置
    oldUnits = ax.Units;
    ax.Units = 'inches';
    
    % TightInset: 为容纳 tick label/axis label/title 等文字，plot box 四周需要的最小边距
    ti(i,:) = ax.TightInset;   % [Left Bottom Right Top]
    
    % Position: plot box 的位置和尺寸
    pos(i,:) = ax.Position;    % [x y w h]
    
    % 恢复原有单位
    ax.Units = oldUnits;

    % 若存在 colorbar，测量其位置（用于统一导出画布布局）
    if includeColorbar
        origCb = [];
        allCbs = findobj(ax.Parent, 'Type', 'ColorBar');
        for j = 1:numel(allCbs)
            if isprop(allCbs(j), 'Axes') && isequal(allCbs(j).Axes, ax)
                origCb = allCbs(j);
                break;
            end
        end

        if ~isempty(origCb) && isvalid(origCb)
            cbHandleList(i) = origCb;

            oldCbUnits = origCb.Units;
            origCb.Units = 'inches';
            cbPos = origCb.Position; % [x y w h] (inches)
            origCb.Units = oldCbUnits;

            cbWidth(i) = cbPos(3);

            axLeft = pos(i, 1);
            axRight = pos(i, 1) + pos(i, 3);
            cbLeft = cbPos(1);
            cbRight = cbPos(1) + cbPos(3);

            if cbLeft >= axRight
                cbSideFlag(i) = 1;
                cbGap(i) = cbLeft - axRight;
            elseif cbRight <= axLeft
                cbSideFlag(i) = -1;
                cbGap(i) = axLeft - cbRight;
            else
                cbSideFlag(i) = 0;
                cbGap(i) = 0;
            end
        end
    end
end

%% 计算统一的页面尺寸和plot box位置
% 以第一个axes的plot box尺寸作为参考（假设所有子图尺寸一致）
innerW = pos(1, 3);  % plot box 宽度
innerH = pos(1, 4);  % plot box 高度

% 取所有axes的最大边距需求 + 用户额外指定的边距
% 这样确保所有子图的内容都能完整显示，且白边统一为上限值
marg = max(ti, [], 1) + pad;   % [Left Bottom Right Top]

% 颜色条布局：仅支持“左右侧竖直 colorbar”（最常见的 east/westoutside）
hasCbRight = any(cbSideFlag == 1);
hasCbLeft = any(cbSideFlag == -1);
hasCb = hasCbRight || hasCbLeft;

if hasCbRight && hasCbLeft
    error('Mixed left/right colorbar locations detected. Please unify colorbar side before export.');
end

cbGapMax = max(cbGap);
cbWidthMax = max(cbWidth);

% 最终导出页面尺寸（所有子图相同）
figH = innerH + marg(2) + marg(4);  % 高度 = plot box + 下边距 + 上边距

if hasCbRight
    figW = innerW + marg(1) + cbGapMax + cbWidthMax + marg(3);
    axPos = [marg(1), marg(2), innerW, innerH];  % [x y w h] inches
    cbPosUniform = [marg(1) + innerW + cbGapMax, marg(2), cbWidthMax, innerH];
elseif hasCbLeft
    figW = marg(1) + cbWidthMax + cbGapMax + innerW + marg(3);
    axPos = [marg(1) + cbWidthMax + cbGapMax, marg(2), innerW, innerH];
    cbPosUniform = [marg(1), marg(2), cbWidthMax, innerH];
else
    figW = innerW + marg(1) + marg(3);  % 宽度 = plot box + 左边距 + 右边距
    axPos = [marg(1), marg(2), innerW, innerH];  % [x y w h] inches
    cbPosUniform = [];
end

%% 逐个导出axes为固定尺寸的PDF
for i = 1:n
    ax = axList(i);
    
    % 创建临时不可见figure
    % 注意：Renderer 属性在 R2019a 中有效，虽然有将来删除的警告但暂时可用
    f = figure('Visible', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1 1 figW figH], ...
        'PaperUnits', 'inches', ...
        'PaperPosition', [0 0 figW figH], ...
        'PaperSize', [figW figH], ...
        'Renderer', renderer);

    % 尽量保持与原 figure 一致的 colormap（对含 colorbar 的图很重要）
    try
        origFig = ancestor(ax, 'figure');
        if ~isempty(origFig) && isvalid(origFig)
            colormap(f, colormap(origFig));
        end
    catch
        % ignore
    end

    % 查找与当前 axes 关联的 legend
    % legend 是独立对象，需要与 axes 一起复制
    origLegend = [];
    allLegends = findobj(ax.Parent, 'Type', 'Legend');
    for j = 1:numel(allLegends)
        % 检查这个 legend 是否属于当前 axes
        if isprop(allLegends(j), 'Axes') && isequal(allLegends(j).Axes, ax)
            origLegend = allLegends(j);
            break;
        end
    end

    % 查找与当前 axes 关联的 colorbar（若存在）
    origCb = [];
    if includeColorbar && isgraphics(cbHandleList(i))
        origCb = cbHandleList(i);
    end
    
    % 复制 axes（和 legend，如果存在）到临时 figure
    % 注意：copyobj 返回顺序不确定（可能 legend 在前、axes 在后）
    % 所以不能用 copiedObjs(1) 作为 newAx
    objToCopy = ax;
    if ~isempty(origLegend) && isvalid(origLegend)
        objToCopy = [objToCopy, origLegend];
    end
    if ~isempty(origCb) && isvalid(origCb)
        objToCopy = [objToCopy, origCb];
    end
    copyobj(objToCopy, f);
    
    % 关键修复：使用 findobj 在新 figure 中查找 axes 句柄
    % 这样可以确保拿到的是真正的 axes，而不是 legend
    newAx = findobj(f, 'Type', 'axes');
    
    % 防御：如果出现多个 axes（极少见），选面积最大的那个
    if isempty(newAx)
        error('No axes found after copyobj().');
    elseif numel(newAx) > 1
        areas = arrayfun(@(h) prod(h.Position(3:4)), newAx);
        [~, imax] = max(areas);
        newAx = newAx(imax);
    else
        newAx = newAx(1);
    end
    
    % 强制设置相同的 plot box 位置和尺寸
    newAx.Units = 'inches';
    newAx.Position = axPos;
    
    % 保持 plot box 固定，防止 MATLAB 根据内容自动缩放
    % R2019a 使用 ActivePositionProperty，R2019b+ 使用 PositionConstraint
    if isprop(newAx, 'PositionConstraint')
        newAx.PositionConstraint = 'innerposition';
    elseif isprop(newAx, 'ActivePositionProperty')
        newAx.ActivePositionProperty = 'position';
    end

    % 若存在 colorbar，强制设置一致的 colorbar 位置/尺寸
    if hasCb && ~isempty(cbPosUniform)
        newCbs = findobj(f, 'Type', 'ColorBar');
        newCb = [];
        for j = 1:numel(newCbs)
            if isprop(newCbs(j), 'Axes') && isequal(newCbs(j).Axes, newAx)
                newCb = newCbs(j);
                break;
            end
        end

        if ~isempty(newCb) && isvalid(newCb)
            oldCbUnits = newCb.Units;
            newCb.Units = 'inches';
            newCb.Position = cbPosUniform;
            newCb.Units = oldCbUnits;
        end
    end
    
    % 确保临时 figure 布局完成
    drawnow;
    
    % 构建输出文件路径
    outFile = fullfile(outDir, [fileNames{i}, '.pdf']);
    
    % 导出 PDF
    % -dpdf: PDF 格式
    % -painters: 矢量渲染器（适合学术论文）
    % -loose: 不紧裁剪，保留设置的 PaperSize
    if useLoose
        print(f, outFile, '-dpdf', '-painters', '-loose');
    else
        print(f, outFile, '-dpdf', '-painters');
    end
    
    % 关闭临时 figure
    close(f);
    
    fprintf('Exported: %s\n', outFile);
end

%% 输出汇总
fprintf('All %d axes exported to: %s\n', n, outDir);
fprintf('Page size: %.2f x %.2f inches\n', figW, figH);
fprintf('Plot box position: [%.2f, %.2f, %.2f, %.2f] inches\n', axPos);

end
