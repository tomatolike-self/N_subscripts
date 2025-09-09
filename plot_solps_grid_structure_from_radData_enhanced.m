function plot_solps_grid_structure_from_radData_enhanced(all_radiationData)
    %PLOT_SOLPS_GRID_STRUCTURE_FROM_RADDATA_ENHANCED 增强版绘制SOLPS网格图
    %   此函数基于原有函数扩展，增加计算网格区域划分图的绘制，并对物理网格区域进行上色
    %   输入参数与原函数相同：
    %   all_radiationData: 包含算例信息的cell数组，每个cell包含dirName字段
    
    % 颜色定义 - 与图片保持一致
    color_core        = [144, 238, 144]/255;  % 绿色 - Core
    color_main_SOL    = [255, 99, 71]/255;    % 橙红色(番茄色) - Main SOL
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

        fprintf('Processing case: %s\n', dirPath);

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
                        fprintf('Found %s: %s\n', fileName, filePath);
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
                        fprintf('Found %s: %s\n', fileName, filePath);
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
                        fprintf('Found %s: %s\n', fileName, filePath);
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
                        fprintf('Found %s: %s\n', fileName, filePath);
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
                        fprintf('Found %s: %s\n', fileName, filePath);
                        break;
                    end
                end
                fort35 = filePath;
            end

            if isempty(filePath)
                fprintf('Warning: %s not found in %s. Skipping this case.\n', fileName, dirPath);
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
            fprintf('Error reading files in %s: %s\n', dirPath, ME.message);
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
            % 分离面索引换算说明（为何原始网格使用 14 = 12+2）：
            % - 计算网格（去除首尾各1层保护单元）中，分离面位于 iy=12 与 13 之间
            % - 映射回原始网格（含两侧各1层保护单元），分离面位于 13(=12+1) 与 14 之间
            % - 若涉及 fna_mdf 的径向通量，其定义在“当前网格与其下方网格的交界面”上，
            %   因此穿过分离面的通量对应原始网格 j=14（即 12+2），并非“额外加两层保护单元”
            j_sep = 14; % 分离面（原始网格 j=14）
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
        
        % 图例已移除 - 相关信息直接显示在图中
        
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
        fprintf('Physical grid plot saved to: %s\n', filenameFIG_physical);
        
        % ------------------------------- 绘制计算网格区域划分图 -------------------------------
        figure('Position', [150, 150, 1200, 800], 'Color', 'white');  % 增加高度以容纳所有内容
        
        % 创建计算网格区域划分图
        nx = 96;  % SOLPS的ix坐标维度（网格单元数）
        ny = 26;  % SOLPS的iy坐标维度（网格单元数）

        % 设置白色背景
        set(gcf, 'Color', 'white');
        set(gca, 'Color', 'white');

        % 调整图形边距，为标签留出更多空间
        set(gca, 'Position', [0.1 0.1 0.8 0.8]);

        % 区域边界定义（按网格单元）
        outer_div_end = 24;     % 外偏滤器结束位置 (网格单元1-24，共24列)
        inner_div_start = 73;   % 内偏滤器开始位置 (网格单元73-96，共24列)
        separatrix_line = 12;   % 分离面位置（网格单元12和13之间）

        % 特殊位置（按网格单元）
        omp_pos = 41;           % OMP位置
        imp_pos = 58;           % IMP位置
        ode_pos = 24;           % ODE位置
        ide_pos = 73;           % IDE位置

        % 创建区域矩阵 - 使用网格方式
        grid_matrix = zeros(ny, nx);  % 注意：矩阵是(行,列)，对应(y,x)

        % 定义区域代码
        OUTER_DIV = 1;   % 外偏滤器
        CORE = 2;        % 核心
        MAIN_SOL = 3;    % 主SOL
        INNER_DIV = 4;   % 内偏滤器

        % 填充区域矩阵
        for i = 1:nx
            for j = 1:ny
                if i <= outer_div_end  % 外偏滤器区域 (1-24列)
                    grid_matrix(j, i) = OUTER_DIV;
                elseif i >= inner_div_start  % 内偏滤器区域 (73-96列)
                    grid_matrix(j, i) = INNER_DIV;
                else  % 中间区域 (25-72列)
                    if j <= separatrix_line  % 核心区域 (1-12行)
                        grid_matrix(j, i) = CORE;
                    else  % 主SOL区域 (13-26行)
                        grid_matrix(j, i) = MAIN_SOL;
                    end
                end
            end
        end

        % 定义颜色映射 - 与物理网格颜色保持一致
        colormap_custom = [
            color_outer_div;    % 蓝色 - Outer Divertor
            color_core;         % 绿色 - Core
            color_main_SOL;     % 橙红色 - Main SOL
            color_inner_div     % 粉红色 - Inner Divertor
        ];

        % 设置白色背景，不使用颜色填充
        % imagesc(1:nx, 1:ny, grid_matrix);  % 注释掉颜色填充
        % colormap(colormap_custom);         % 注释掉颜色映射
        hold on;
        
        % 添加带颜色的网格线 - 根据区域使用不同颜色
        % 垂直网格线 - 按区域分段绘制
        for i = 0.5:1:(nx+0.5)
            if i <= outer_div_end + 0.5  % 外偏滤器区域
                % 整条线都使用外偏滤器颜色
                plot([i i], [0.5 ny+0.5], 'Color', color_outer_div, 'LineWidth', 1.0);
            elseif i >= inner_div_start - 0.5  % 内偏滤器区域
                % 整条线都使用内偏滤器颜色
                plot([i i], [0.5 ny+0.5], 'Color', color_inner_div, 'LineWidth', 1.0);
            else  % 中间区域（核心和主SOL）- 分段绘制
                % 核心区域段 (1-12行)
                plot([i i], [0.5 separatrix_line+0.5], 'Color', color_core, 'LineWidth', 1.0);
                % 主SOL区域段 (13-26行)
                plot([i i], [separatrix_line+0.5 ny+0.5], 'Color', color_main_SOL, 'LineWidth', 1.0);
            end
        end

        % 水平网格线 - 按区域分段绘制
        for j = 0.5:1:(ny+0.5)
            % 外偏滤器区域段 (1-24列) - 整个区域都使用外偏滤器颜色
            plot([0.5 outer_div_end+0.5], [j j], 'Color', color_outer_div, 'LineWidth', 1.0);

            % 中间区域段 (25-72列) - 根据径向位置区分核心和主SOL
            if j <= separatrix_line + 0.5  % 核心区域
                line_color = color_core;
            else  % 主SOL区域
                line_color = color_main_SOL;
            end
            plot([outer_div_end+0.5 inner_div_start-0.5], [j j], 'Color', line_color, 'LineWidth', 1.0);

            % 内偏滤器区域段 (73-96列) - 整个区域都使用内偏滤器颜色
            plot([inner_div_start-0.5 nx+0.5], [j j], 'Color', color_inner_div, 'LineWidth', 1.0);
        end

        % 强调特定位置
        % 分离面 - 黑色实线（在第12行和第13行之间）
        plot([0.5 nx+0.5], [separatrix_line+0.5 separatrix_line+0.5], 'k-', 'LineWidth', 3);
        text(50, separatrix_line+2, 'Separatrix', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);

        % 垂直分隔线 - 黑色虚线
        plot([outer_div_end+0.5 outer_div_end+0.5], [0.5 ny+0.5], 'k--', 'LineWidth', 2);
        plot([inner_div_start-0.5 inner_div_start-0.5], [0.5 ny+0.5], 'k--', 'LineWidth', 2);
        plot([omp_pos+0.5 omp_pos+0.5], [0.5 ny+0.5], 'k--', 'LineWidth', 2);
        plot([imp_pos+0.5 imp_pos+0.5], [0.5 ny+0.5], 'k--', 'LineWidth', 2);
        
        % 添加区域标签 - 使用白色背景和边框确保文字清晰可见
        text(50, 7, 'Core', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);
        text(50, 21, 'Main SOL', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);
        text(12, 7, 'PFR', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);
        text(86, 7, 'PFR', 'FontSize', 36, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);

        % 添加偏滤器SOL区域标签（在PFR上方，径向网格13-26区域）
        text(12, 21, 'Outer Div. SOL', 'FontSize', 28, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);
        text(86, 21, 'Inner Div. SOL', 'FontSize', 28, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'LineWidth', 0.5, 'Margin', 2);

        % 添加特殊位置标记 - 这些标记位于图形上方，不与网格重叠，因此不需要背景
        text(1, ny+2, 'OT', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(outer_div_end, ny+2, 'ODE', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(omp_pos, ny+2, 'OMP', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(imp_pos, ny+2, 'IMP', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(inner_div_start, ny+2, 'IDE', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        text(nx, ny+2, 'IT', 'FontSize', 32, 'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
        
        % 添加标签
        xlabel('$Poloidal$', 'FontName', 'Times New Roman', 'FontSize', 32, 'Interpreter', 'latex');
        ylabel('$Radial$', 'FontName', 'Times New Roman', 'FontSize', 32, 'Interpreter', 'latex');
        
        % 图例已移除 - 相关信息直接显示在图中
        
        % 修改刻度字体大小
        set(gca, 'FontSize', 30);
        
        % 调整轴范围和比例
        axis([0.5 nx+0.5 0.5 ny+0.5]);
        set(gca, 'YDir', 'normal'); % 确保y轴向上
        set(gca, 'XTick', [1, 24, 41, 58, 73, 96]);
        set(gca, 'YTick', [1, 12, 26]);

        % 确保所有文字对象都在最上层显示
        % 获取当前坐标轴中的所有文字对象
        text_objects = findobj(gca, 'Type', 'text');
        % 将所有文字对象移到最上层
        if ~isempty(text_objects)
            uistack(text_objects, 'top');
        end
        
        % 保存计算网格图
        filenameFIG_computational = fullfile(pwd, sprintf('SOLPS_computational_grid_%s_%s.fig', currentDateTime, lastDirName));
        saveas(gcf, filenameFIG_computational, 'fig');
        fprintf('Computational grid plot saved to: %s\n', filenameFIG_computational);
    end
end