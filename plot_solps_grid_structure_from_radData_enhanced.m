function plot_solps_grid_structure_from_radData_enhanced(all_radiationData)
    %PLOT_SOLPS_GRID_STRUCTURE_FROM_RADDATA_ENHANCED 增强版绘制SOLPS网格图
    %   此函数基于原有函数扩展，增加计算网格区域划分图的绘制，并对物理网格区域进行上色
    %   输入参数与原函数相同：
    %   all_radiationData: 包含算例信息的cell数组，每个cell包含dirName字段
    
    % 颜色定义 - 与图片保持一致
    color_core        = [144, 238, 144]/255;  % 绿色 - Core
    color_main_SOL    = [255, 99, 71]/255;    % 红色 - Main SOL
    color_inner_div   = [255, 0, 255]/255;    % 粉红色 - Inner Divertor
    color_outer_div   = [0, 0, 255]/255;      % 蓝色 - Outer Divertor
    color_PFR         = [230, 230, 250]/255;  % 浅紫色 - PFR（仅在图例中使用）
    
    color_separatrix  = [0, 0, 0];            % 黑色 - 分离面
    color_normal_grid = [200, 200, 200]/255;  % 浅灰色 - 普通网格
    color_structure   = [0, 0, 0];            % 黑色 - 结构

    % 全局字体设置
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontName', 'Times New Roman');

    % 遍历all_radiationData中的每个算例
    for i = 1:length(all_radiationData)
        radData = all_radiationData{i};
        dirPath = radData.dirName;

        fprintf('处理算例: %s\n', dirPath);

        % 获取父目录和祖父目录
        parentDir = fileparts(dirPath);
        grandparentDir = fileparts(parentDir);

        % 初始化文件路径变量
        structure_file = '';
        gmtry_file = '';
        fort33 = '';
        fort34 = '';
        fort35 = '';

        fileNames = {'structure.dat', 'b2fgmtry', 'fort.33', 'fort.34', 'fort.35'};

        % 遍历需要查找的文件
        found_all_files = true;
        for iFile = 1:length(fileNames)
            fileName = fileNames{iFile};
            filePath = '';

            if strcmp(fileName, 'structure.dat')
                % structure.dat的查找路径
                possible_files_structure = {
                    fullfile(parentDir, 'baserun', fileName),
                    fullfile(grandparentDir, 'baserun', fileName),
                    fullfile(dirPath, fileName),
                    fullfile(parentDir, fileName),
                    fullfile(grandparentDir, fileName)
                };
                for p_ = 1:length(possible_files_structure)
                    if exist(possible_files_structure{p_}, 'file')
                        filePath = possible_files_structure{p_};
                        fprintf('找到%s: %s\n', fileName, filePath);
                        break;
                    end
                end
                structure_file = filePath;
            elseif strcmp(fileName, 'b2fgmtry')
                % b2fgmtry只在dirPath查找
                possible_files_other = {
                    fullfile(dirPath, fileName)
                };
                for p_ = 1:length(possible_files_other)
                    if exist(possible_files_other{p_}, 'file')
                        filePath = possible_files_other{p_};
                        fprintf('找到%s: %s\n', fileName, filePath);
                        break;
                    end
                end
                gmtry_file = filePath;
            elseif strcmp(fileName, 'fort.33')
                % fort.33只在dirPath查找
                possible_files_other = {
                    fullfile(dirPath, fileName)
                };
                for p_ = 1:length(possible_files_other)
                    if exist(possible_files_other{p_}, 'file')
                        filePath = possible_files_other{p_};
                        fprintf('找到%s: %s\n', fileName, filePath);
                        break;
                    end
                end
                fort33 = filePath;
            elseif strcmp(fileName, 'fort.34')
                % fort.34只在dirPath查找
                possible_files_other = {
                    fullfile(dirPath, fileName)
                };
                for p_ = 1:length(possible_files_other)
                    if exist(possible_files_other{p_}, 'file')
                        filePath = possible_files_other{p_};
                        fprintf('找到%s: %s\n', fileName, filePath);
                        break;
                    end
                end
                fort34 = filePath;
            elseif strcmp(fileName, 'fort.35')
                % fort.35只在dirPath查找
                possible_files_other = {
                    fullfile(dirPath, fileName)
                };
                for p_ = 1:length(possible_files_other)
                    if exist(possible_files_other{p_}, 'file')
                        filePath = possible_files_other{p_};
                        fprintf('找到%s: %s\n', fileName, filePath);
                        break;
                    end
                end
                fort35 = filePath;
            end

            if isempty(filePath)
                fprintf('警告: 在%s中未找到%s. 跳过此算例的绘图。\n', dirPath, fileName);
                found_all_files = false;
                break;
            end
        end

        if ~found_all_files
            continue;
        end

        % 读取数据
        try
            structure = read_structure(structure_file);
            gmtry = read_b2fgmtry(gmtry_file);
            triangle = read_triangle_mesh(fort33, fort34, fort35);
        catch ME
            fprintf('读取%s中的文件时出错: %s\n', dirPath, ME.message);
            continue;
        end

        % ------------------------------- 绘制物理网格与结构图 -------------------------------
        figure('Position', [100, 100, 1200, 900]);
        
        plotstructure(structure, 'color', color_structure, 'LineWidth', 1, 'HandleVisibility', 'off');
        hold on;
        
        % 首先为整个网格绘制基础网格线
        plotgrid(gmtry, 'Color', color_normal_grid, 'LineStyle', '-', 'LineWidth', 0.1, 'HandleVisibility', 'off');
        hold on;
        
        % 填充不同区域颜色
        % 对每个网格单元进行遍历并上色
        for i_cell = 1:98
            for j_cell = 1:28
                % 获取当前网格单元的四个角点坐标
                rco = [gmtry.crx(i_cell,j_cell,1), gmtry.crx(i_cell,j_cell,2), gmtry.crx(i_cell,j_cell,4), gmtry.crx(i_cell,j_cell,3), gmtry.crx(i_cell,j_cell,1)];
                zco = [gmtry.cry(i_cell,j_cell,1), gmtry.cry(i_cell,j_cell,2), gmtry.cry(i_cell,j_cell,4), gmtry.cry(i_cell,j_cell,3), gmtry.cry(i_cell,j_cell,1)];
                
                % 根据区域位置决定填充颜色
                if i_cell <= 25 % 外偏滤器区域 (包含PFR部分)
                    fill(rco, zco, color_outer_div, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                elseif i_cell >= 74 % 内偏滤器区域 (包含PFR部分)
                    fill(rco, zco, color_inner_div, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                else % 核心和主SOL区域
                    if j_cell <= 13 % 核心区域
                        fill(rco, zco, color_core, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                    else % 主SOL区域
                        fill(rco, zco, color_main_SOL, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                    end
                end
            end
        end
        
        % 重新绘制网格线，确保颜色填充后网格线仍然可见
        plotgrid(gmtry, 'Color', color_normal_grid, 'LineStyle', '-', 'LineWidth', 0.1, 'HandleVisibility', 'off');
        
        % 绘制分离面
        for i_sep = 1:98
            j_sep = 14; % 分离面
            rco = [gmtry.crx(i_sep,j_sep,1), gmtry.crx(i_sep,j_sep,2)];
            zco = [gmtry.cry(i_sep,j_sep,1), gmtry.cry(i_sep,j_sep,2)];
            plot(rco, zco, 'Color', color_separatrix, 'LineWidth', 2);
            hold on;
        end
        
        % 标记重要位置
        % OMP, IMP标记
        i_OMP = 42;
        % 绘制整条42号极向网格线
        for j = 1:28
            rco = [gmtry.crx(i_OMP,j,3), gmtry.crx(i_OMP,j,4)];
            zco = [gmtry.cry(i_OMP,j,3), gmtry.cry(i_OMP,j,4)];
            plot(rco, zco, 'k-', 'LineWidth', 1.5);
        end
        % 在空白处添加OMP标签
        text(gmtry.crx(i_OMP,1,1) - 0.15, gmtry.cry(i_OMP,1,1) - 0.05, 'OMP', 'FontSize', 24, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        i_IMP = 59;
        % 绘制整条59号极向网格线
        for j = 1:28
            rco = [gmtry.crx(i_IMP,j,3), gmtry.crx(i_IMP,j,4)];
            zco = [gmtry.cry(i_IMP,j,3), gmtry.cry(i_IMP,j,4)];
            plot(rco, zco, 'k-', 'LineWidth', 1.5);
        end
        % 在空白处添加IMP标签
        text(gmtry.crx(i_IMP,28,1) + 0.25, gmtry.cry(i_IMP,28,1) + 0.05, 'IMP', 'FontSize', 24, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        % 设置图形属性
        xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex');
        
        % 创建图例
        h_legend = zeros(4, 1);
        h_legend(1) = fill(NaN, NaN, color_inner_div, 'EdgeColor', 'none');
        h_legend(2) = fill(NaN, NaN, color_main_SOL, 'EdgeColor', 'none');
        h_legend(3) = fill(NaN, NaN, color_outer_div, 'EdgeColor', 'none');
        h_legend(4) = fill(NaN, NaN, color_core, 'EdgeColor', 'none');
        
        legend(h_legend, {'Inner Div.', 'Main SOL', 'Outer Div.', 'Core'}, 'FontName', 'Times New Roman', 'FontSize', 20, 'Location', 'northeast');
        
        % 修改刻度字体大小
        set(gca, 'FontSize', 22);

        % 在绘制完所有图形内容后，添加以下两行
        axis equal;  % 确保R和Z轴使用相同的比例尺
        axis tight;  % 使坐标轴紧贴数据范围
        
        
        % 保存物理网格图
        currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');
        [~, lastDirName, ~] = fileparts(radData.dirName);
        filenameFIG_physical = fullfile(pwd, sprintf('SOLPS_physical_grid_%s_%s.fig', currentDateTime, lastDirName));
        saveas(gcf, filenameFIG_physical, 'fig');
        fprintf('物理网格图已保存至: %s\n', filenameFIG_physical);
        
        % ------------------------------- 绘制计算网格区域划分图 -------------------------------
        figure('Position', [150, 150, 1200, 800], 'Color', 'white');  % 增加高度以容纳所有内容
        
        % 创建计算网格区域划分图
        nx = 96;  % SOLPS的ix坐标维度
        ny = 26;  % SOLPS的iy坐标维度
        
        % 设置白色背景
        set(gcf, 'Color', 'white');
        set(gca, 'Color', 'white');
        
        % 调整图形边距，为标签留出更多空间
        set(gca, 'Position', [0.1 0.1 0.8 0.8]);
        
        % 区域边界定义
        inner_div_end = 24;     % 内偏滤器结束位置
        outer_div_start = 73;   % 外偏滤器开始位置
        separatrix_line = 12;   % 分离面位置（13和14之间）
        
        % 特殊位置 - 保持原有位置
        omp_pos = 41;           % OMP位置
        imp_pos = 58;           % IMP位置
        ode_pos = 24;           % ODE位置
        ide_pos = 73;           % IDE位置
        
        % 绘制网格线 - 不同区域使用不同颜色
        hold on;
        
        % 绘制极向网格线（垂直线）
        for i = 1:nx
            if i <= inner_div_end  % 内偏滤器区域
                plot([i i], [1 ny], 'm-', 'LineWidth', 0.5);  % 粉色线
            elseif i >= outer_div_start  % 外偏滤器区域
                plot([i i], [1 ny], 'b-', 'LineWidth', 0.5);  % 蓝色线
            else  % 中间区域 - 分Core和SOL两段绘制
                % Core区域部分用绿色
                plot([i i], [1 separatrix_line+1], 'g-', 'LineWidth', 0.5);  % 绿色线
                % SOL区域部分用红色
                plot([i i], [separatrix_line+1 ny], 'r-', 'LineWidth', 0.5);  % 红色线
            end
        end
        
        % 绘制径向网格线（水平线）
        for j = 1:ny
            if j <= separatrix_line+1  % 核心和PFR区域
                for i = 1:nx
                    if (i > inner_div_end && i < outer_div_start)  % 核心区域
                        x_start = max(i, inner_div_end+1);
                        x_end = min(i+1, outer_div_start);
                        plot([x_start x_end], [j j], 'g-', 'LineWidth', 0.5);  % 绿色线
                    elseif i <= inner_div_end  % 内PFR区域
                        plot([i i+1], [j j], 'm-', 'LineWidth', 0.5);  % 粉色线
                    else  % 外PFR区域
                        plot([i i+1], [j j], 'b-', 'LineWidth', 0.5);  % 蓝色线
                    end
                end
            else  % SOL区域
                for i = 1:nx
                    if (i > inner_div_end && i < outer_div_start)  % 主SOL区域
                        x_start = max(i, inner_div_end+1);
                        x_end = min(i+1, outer_div_start);
                        plot([x_start x_end], [j j], 'r-', 'LineWidth', 0.5);  % 红色线
                    elseif i <= inner_div_end  % 内偏滤器区域
                        plot([i i+1], [j j], 'm-', 'LineWidth', 0.5);  % 粉色线
                    else  % 外偏滤器区域
                        plot([i i+1], [j j], 'b-', 'LineWidth', 0.5);  % 蓝色线
                    end
                end
            end
        end
        
        % 强调特定位置
        % 分离面 - 黑色实线
        plot([1 nx], [separatrix_line+1 separatrix_line+1], 'k-', 'LineWidth', 2);
        text(50, separatrix_line+2, 'Separatrix', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        % 垂直分隔线 - 黑色虚线
        plot([inner_div_end+1 inner_div_end+1], [1 ny], 'k--', 'LineWidth', 1.5);
        plot([outer_div_start outer_div_start], [1 ny], 'k--', 'LineWidth', 1.5);
        plot([omp_pos omp_pos], [1 ny], 'k--', 'LineWidth', 1.5);
        plot([imp_pos imp_pos], [1 ny], 'k--', 'LineWidth', 1.5);
        
        % 添加区域标签
        text(50, 7, 'Core', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(50, 21, 'SOL', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(12, 7, 'PFR', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(86, 7, 'PFR', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        % 添加特殊位置标记
        text(1, ny+2, 'OT', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(inner_div_end, ny+2, 'ODE', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(omp_pos, ny+2, 'OMP', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(imp_pos, ny+2, 'IMP', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(outer_div_start, ny+2, 'IDE', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(nx, ny+2, 'IT', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        % 添加标签
        xlabel('$Poloidal$', 'FontName', 'Times New Roman', 'FontSize', 32, 'Interpreter', 'latex');
        ylabel('$Radial$', 'FontName', 'Times New Roman', 'FontSize', 32, 'Interpreter', 'latex');
        
        % 创建图例
        h_legend = zeros(4, 1);
        h_legend(1) = plot(NaN, NaN, 'm-', 'LineWidth', 2);
        h_legend(2) = plot(NaN, NaN, 'r-', 'LineWidth', 2);
        h_legend(3) = plot(NaN, NaN, 'b-', 'LineWidth', 2);
        h_legend(4) = plot(NaN, NaN, 'g-', 'LineWidth', 2);
        
        legend(h_legend, {'Inner Div.', 'Main SOL', 'Outer Div.', 'Core'}, 'FontName', 'Times New Roman', 'FontSize', 36, 'Location', 'northeast');
        
        % 修改刻度字体大小
        set(gca, 'FontSize', 30);
        
        % 调整轴范围和比例
        axis([1 nx 1 ny]);
        set(gca, 'YDir', 'normal'); % 确保y轴向上
        set(gca, 'XTick', [1, 24, 41, 58, 73, 96]);
        set(gca, 'YTick', [1, 12, 26]);
        
        % 保存计算网格图
        filenameFIG_computational = fullfile(pwd, sprintf('SOLPS_computational_grid_%s_%s.fig', currentDateTime, lastDirName));
        saveas(gcf, filenameFIG_computational, 'fig');
        fprintf('计算网格图已保存至: %s\n', filenameFIG_computational);
    end
end