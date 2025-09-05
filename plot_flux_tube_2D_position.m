function plot_flux_tube_2D_position(all_radiationData, radial_index_for_nearSOL, varargin)
    % =========================================================================
    % 功能：
    %   绘制选定通量管的2D位置可视化，将多个选定的通量管绘制到一个图上
    %
    % 说明：
    %   1) 不再从文件读取 b2fplasmf / b2fgmtry，而是从 all_radiationData
    %      中直接获取 .gmtry 与 .plasma 等数据；
    %   2) 参考 plot_nearSOL_distributions_pol.m 中的绘图格式和样式；
    %   3) 将多个径向索引对应的通量管都绘制到同一个图上，使用不同颜色区分；
    %   4) 使用学术出版标准的字体和格式设置；
    %
    % 输入参数：
    %   all_radiationData         - cell 数组，每个元素含有:
    %                                .dirName (string)
    %                                .gmtry   (b2fgmtry 解析结果)
    %                                .plasma  (b2fplasmf解析结果)
    %   radial_index_for_nearSOL  - 指定近SOL的径向索引，可以指定多个，用空格分隔
    %                                 例如：'17 18 19' 或 [17, 18, 19]
    %   varargin                  - 可选参数：
    %                                 'domain', 0/1/2 - 绘图区域选择
    %                                   0: 全域 (默认)
    %                                   1: 上偏滤器 (EAST updiv)
    %                                   2: 下偏滤器 (EAST down-div)
    %
    % 作者：xxx
    % 日期：2025-01-31
    %
    % 修改备注：
    %   - 去除文件读取，使用已有的 gmtry, plasma 数据
    %   - 参考 plot_nearSOL_distributions_pol.m 的绘图格式和样式
    %   - radial_index_for_nearSOL 可以接受多个索引值
    %   - 将多个通量管绘制到同一个图上，使用不同颜色和图例区分
    %   - 使用 Times New Roman 字体和学术出版标准格式
    %   - 2025-01-31: 重构为统一绘图模式，所有选定通量管显示在一个图中
    % =========================================================================

    % 解析可选参数
    p = inputParser;
    addParameter(p, 'domain', 0, @(x) isnumeric(x) && ismember(x, [0,1,2]));
    parse(p, varargin{:});

    domain = p.Results.domain;

    % 检查 radial_index_for_nearSOL 输入类型，并转换为数值数组
    if ischar(radial_index_for_nearSOL)
        radial_indices = str2num(radial_index_for_nearSOL); % 字符串转数值数组
    elseif isnumeric(radial_index_for_nearSOL)
        radial_indices = radial_index_for_nearSOL;          % 直接使用数值数组
    else
        error('radial_index_for_nearSOL input type error, should be string or numeric array');
    end

    % 显示网格维度信息（使用第一个算例的数据）
    if ~isempty(all_radiationData)
        first_gmtry = all_radiationData{1}.gmtry;
        [nxd_display, nyd_display] = size(first_gmtry.crx(:,:,1));
        fprintf('>>> Grid dimensions used: %d x %d (poloidal x radial)\n', nxd_display, nyd_display);
        fprintf('>>> radial_index_for_nearSOL is specified on this %d x %d grid\n', nxd_display, nyd_display);
        fprintf('>>> Valid radial index range: 1 to %d\n', nyd_display);
    end

    % ========== (4) 绘制选中的全部通量管 ==========
    % 创建一个仅显示所有选定通量管线条的图
    % 从第一个算例拿来 gmtry 做可视化
    gmtry_first = all_radiationData{1}.gmtry;
    [~, ny] = size(gmtry_first.crx(:,:,1)); % 获取网格尺寸
    
    % 计算网格中心坐标
    rCenter = mean(gmtry_first.crx, 3);
    zCenter = mean(gmtry_first.cry, 3);
    
    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name', sprintf('Selected flux tubes (iy=%s)', num2str(radial_indices)), ...
           'NumberTitle', 'off', 'Color', 'w', ...
           'Units', 'inches', 'Position', [1, 1, 12, 10]);  % 增大图窗尺寸
    
    % 设置坐标轴和背景
    hold on;
    
    % 添加分离器线和结构，但不显示在图例中
    h_sep = plot3sep(gmtry_first, 'color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
    % 确保分离器线不出现在图例中
    for i = 1:length(h_sep)
        set(h_sep(i), 'HandleVisibility', 'off');
    end
    
    % 如果有结构数据，也添加结构线
    if isfield(all_radiationData{1}, 'structure')
        h_struct = plotstructure(all_radiationData{1}.structure, 'color', 'k', 'LineWidth', 2.5);
        % 确保结构线不出现在图例中
        if ~isempty(h_struct)
            for i = 1:length(h_struct)
                set(h_struct(i), 'HandleVisibility', 'off');
            end
        end
    end
    
    % --- 绘制通量管的线条表示 ---
    % 使用较粗的线条以便清晰显示
    fluxTubeLineColor = lines(length(radial_indices)); % 根据通量管数量生成不同颜色
    lineWidth = 4.0; % 增加线条粗细，更符合学术出版要求
    
    % 为每个选定的通量管绘制一条线，收集所有线的句柄
    fluxTubeHandles = gobjects(length(radial_indices), 1);
    fluxTubeLabels = cell(length(radial_indices), 1);
    
    for idx = 1:length(radial_indices)
        j_index = radial_indices(idx);
        fprintf('\n>>> Processing radial index iy = %d on %d x %d grid...\n', j_index, nxd_display, nyd_display);
        
        if j_index <= ny
            % 沿着通量管的每个极向位置绘制线条
            r_path = rCenter(:, j_index);
            z_path = zCenter(:, j_index);
            
            % 绘制路径，使用不同颜色区分不同通量管
            fluxTubeHandles(idx) = plot(r_path, z_path, '-', ...
                'Color', fluxTubeLineColor(mod(idx-1, size(fluxTubeLineColor,1))+1, :), ...
                'LineWidth', lineWidth);
            fluxTubeLabels{idx} = sprintf('iy=%d', j_index);
        end
    end
    
    % 设置坐标轴和标题
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'LineWidth', 2.0, 'Box', 'on');
    xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 40, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 40, 'FontWeight', 'bold', 'Interpreter', 'latex');

    % 根据domain参数设置标题和显示区域
    if domain == 0
        title('Selected flux tubes', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
    elseif domain == 1  % 上偏滤器
        title('Selected flux tubes (Upper Div.)', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
    elseif domain == 2  % 下偏滤器
        title('Selected flux tubes (Lower Div.)', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
    end
    
    % 添加图例，仅显示通量管线条
    lgd = legend(fluxTubeHandles, fluxTubeLabels, 'Location', 'best');
    set(lgd, 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
    
    axis square;
    box on;
    grid on;

    % 根据domain参数设置显示区域
    if domain ~= 0
        if domain == 1  % 上偏滤器
            xlim([1.30, 2.00]);
            ylim([0.50, 1.20]);
        elseif domain == 2  % 下偏滤器
            xlim([1.30, 2.05]);
            ylim([-1.15, -0.40]);
        end
    end
    
    % 保存图片，文件名包含所有选择的通量管索引和区域信息
    indices_str = regexprep(num2str(radial_indices), '\s+', '_');
    if domain == 0
        domain_str = 'whole';
    elseif domain == 1
        domain_str = 'updiv';
    elseif domain == 2
        domain_str = 'downdiv';
    end
    saveFigureWithTimestamp(sprintf('Selected_flux_tubes_iy%s_%s', indices_str, domain_str));

    fprintf('\n>>> Finished: Figures with selected flux tubes for iy=[%s].\n', num2str(radial_indices));

end % end of main function

%% ========== 保存带时间后缀的图子函数 ==========
function saveFigureWithTimestamp(baseName)
    % 将当前 figure 保存为 baseName_YYYYMMDD_HHMMSS.fig
    % 并设置较大窗口、PaperPositionMode='auto' 避免被裁剪
    set(gcf,'Units','pixels','Position',[100 50 1200 800]);
    set(gcf,'PaperPositionMode','auto');

    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);

    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end
