function plot_fluxTube_forces(all_radiationData, radial_index_for_fluxTube)
    %==========================================================================
    % 功能：
    %   沿着选定的通量管（指定径向索引）绘制新的受力图，
    %   包括以下几种主要作用力（单位均为 N）：
    %       1) 摩擦力：
    %            - b2npmo_smaf
    %            - smfr
    %       2) 温度梯度力：
    %            - smpt
    %            - smth
    %       3) 压力梯度力：
    %            - b2npmo_smag
    %
    % 说明：
    %   - 输入参数 all_radiationData 为 cell 数组，每个元素内含有字段：
    %         .dirName (string)
    %         .gmtry   (几何数据结构，需包含字段 hx，用于计算极向距离)
    %         .plasma  (物理量数据结构，需包含各受力变量字段)
    %   - radial_index_for_fluxTube 可为字符串（如 '17 18 19'）或数值数组
    %   - 脚本采用不同颜色区分不同算例（目录），不同线型区分受力种类
    %
    % 作者：xxx
    % 日期：2025-03-04
    %==========================================================================
    
        % 检查 radial_index_for_fluxTube 输入类型，并转换为数值数组
        if ischar(radial_index_for_fluxTube)
            radial_indices = str2num(radial_index_for_fluxTube); %#ok<ST2NM>
        elseif isnumeric(radial_index_for_fluxTube)
            radial_indices = radial_index_for_fluxTube;
        else
            error('radial_index_for_fluxTube 输入类型错误，应为字符串或数值数组');
        end
    
        totalDirs = length(all_radiationData);
    
        % 循环处理每个指定的径向索引（通量管）
        for j_index = radial_indices
            fprintf('\n>>> Processing radial index j = %d for flux tube forces...\n', j_index);
    
            % 创建新图用于绘制选中通量管的各受力变量
            figure('Name', sprintf('Selected Flux Tube Forces (j=%d)', j_index), ...
                   'NumberTitle', 'off', 'Color', 'w', ...
                   'DefaultAxesFontSize', 14, 'DefaultTextFontSize', 18);
            hold on;
    
            % 定义颜色和线型
            line_colors = lines(totalDirs);
            % 定义各受力变量对应的线型（顺序分别为：摩擦力1、摩擦力2、温度梯度力1、温度梯度力2、压力梯度力）
            force_line_styles = {'-', '--', ':', '-.', '-o'};
    
            % --- 创建 Dummy 对象以便在 Legend 中区分目录（颜色） ---
            dummyDirHandles = gobjects(totalDirs,1);
            dirLegendStrings = cell(totalDirs,1);
            for iDir = 1:totalDirs
                ccol = line_colors(mod(iDir-1, size(line_colors,1)) + 1, :);
                dummyDirHandles(iDir) = plot(nan, nan, 'LineStyle', '-', ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility', 'off');
                dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
            end
    
            % --- 创建 Dummy 对象以便在 Legend 中区分物理量（线型） ---
            dummyForceHandles = gobjects(5,1);
            forceLegendStrings = {...
                'Friction force (b2npmo\_smaf, N)',...
                'Friction force (smfr, N)',...
                'Temperature gradient force (smpt, N)',...
                'Temperature gradient force (smth, N)',...
                'Pressure gradient force (b2npmo\_smag, N)'};
            for fIdx = 1:5
                dummyForceHandles(fIdx) = plot(nan, nan, 'LineStyle', force_line_styles{fIdx}, ...
                    'Color', 'k', 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility', 'off');
            end
    
            % --- 对每个算例分别绘制受力变量 ---
            for iDir = 1:totalDirs
                dataStruct = all_radiationData{iDir};
                gmtry_tmp = dataStruct.gmtry;
                plasma_tmp = dataStruct.plasma;
    
                % 获取网格中极向位置个数，并判断径向索引是否越界
                nxd = size(gmtry_tmp.hx, 1);
                if j_index > size(gmtry_tmp.hx, 2)
                    fprintf('Out of range: j=%d for %s\n', j_index, dataStruct.dirName);
                    continue;
                end
    
                % --- 计算沿通量管的极向距离 ---
                pol_len = gmtry_tmp.hx(:, j_index);
                x_edge  = zeros(nxd+1,1);
                for iPos = 1:nxd
                    x_edge(iPos+1) = x_edge(iPos) + pol_len(iPos);
                end
                x_center = 0.5 * (x_edge(1:end-1) + x_edge(2:end));
    
                % --- 提取各受力变量（检查字段存在性） ---
                if isfield(plasma_tmp, 'b2npmo_smaf')
                    force_fric1 = plasma_tmp.b2npmo_smaf(:, j_index);
                else
                    force_fric1 = zeros(nxd,1);
                end
                if isfield(plasma_tmp, 'smfr')
                    force_fric2 = plasma_tmp.smfr(:, j_index);
                else
                    force_fric2 = zeros(nxd,1);
                end
                if isfield(plasma_tmp, 'smpt')
                    force_temp1 = plasma_tmp.smpt(:, j_index);
                else
                    force_temp1 = zeros(nxd,1);
                end
                if isfield(plasma_tmp, 'smth')
                    force_temp2 = plasma_tmp.smth(:, j_index);
                else
                    force_temp2 = zeros(nxd,1);
                end
                if isfield(plasma_tmp, 'b2npmo_smag')
                    force_press = plasma_tmp.b2npmo_smag(:, j_index);
                else
                    force_press = zeros(nxd,1);
                end
    
                % 取当前算例的颜色
                ccol = line_colors(mod(iDir-1, size(line_colors,1)) + 1, :);
    
                % --- 分别绘制各受力变量 ---
                h1 = plot(x_center, force_fric1, 'LineStyle', force_line_styles{1}, ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility','off');
                h2 = plot(x_center, force_fric2, 'LineStyle', force_line_styles{2}, ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility','off');
                h3 = plot(x_center, force_temp1, 'LineStyle', force_line_styles{3}, ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility','off');
                h4 = plot(x_center, force_temp2, 'LineStyle', force_line_styles{4}, ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility','off');
                h5 = plot(x_center, force_press, 'LineStyle', force_line_styles{5}, ...
                    'Color', ccol, 'LineWidth', 2, 'Marker', 'none', 'HandleVisibility','off');
    
                % 可选：将目录名称保存到 UserData 中，以便 DataCursor 显示
                set([h1 h2 h3 h4 h5], 'UserData', dataStruct.dirName);
            end
    
            % --- 设置坐标、标题和网格 ---
            xlabel('Poloidal distance (m)', 'FontSize', 14);
            ylabel('Force (N)', 'FontSize', 14);
            title(sprintf('Selected Flux Tube Forces (j=%d)', j_index), 'FontSize', 16);
            grid on;
    
            % --- 组合 Dummy 对象生成 Legend ---
            allDummyHandles = [dummyDirHandles; dummyForceHandles];
            allLegendStrings = [dirLegendStrings; forceLegendStrings];
            legend(allDummyHandles, allLegendStrings, 'Location', 'best', 'Interpreter', 'none');
    
            % 设置 DataCursor 回调函数
            dcm = datacursormode(gcf);
            set(dcm, 'UpdateFcn', @myDataCursorUpdateFcn);
    
            % 保存图片，文件名带上 j 索引
            saveFigureWithTimestamp(sprintf('FluxTube_Forces_j%d', j_index));
        end
    
        fprintf('\n>>> Finished: Selected Flux Tube Forces plotted for j=[%s].\n', num2str(radial_indices));
    end
    
    %% DataCursor 回调函数
    function txt = myDataCursorUpdateFcn(~, event_obj)
        pos = get(event_obj, 'Position');
        target = get(event_obj, 'Target');
        dirPath = get(target, 'UserData');
        if ~isempty(dirPath)
            txt = {['X: ', num2str(pos(1))], ...
                   ['Y: ', num2str(pos(2))], ...
                   ['Directory: ', dirPath]};
        else
            txt = {['X: ', num2str(pos(1))], ...
                   ['Y: ', num2str(pos(2))]};
        end
    end
    
    %% 保存图形（带时间戳）子函数
    function saveFigureWithTimestamp(baseName)
        % 设置窗口尺寸和 PaperPositionMode 以防止图像被裁剪
        set(gcf, 'Units', 'pixels', 'Position', [100 50 1200 800]);
        set(gcf, 'PaperPositionMode', 'auto');
    
        timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
        outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    
        savefig(outFile);
        fprintf('Figure saved: %s\n', outFile);
    end