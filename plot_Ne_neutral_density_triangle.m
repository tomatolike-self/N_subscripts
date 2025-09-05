function plot_Ne_neutral_density_triangle(all_radiationData, domain)
    % =========================================================================
    % 功能：
    %   针对每个算例(已在 all_radiationData 中存有 gmtry/neut 等信息)，在 2D 平面上绘制：
    %     1) Ne 中性粒子密度分布 - **使用三角网格和对数标尺显示**
    %     2) 优先使用 fort.46 文件中的三角网格密度数据，如果不存在则使用插值方法
    %
    % 输入参数：
    %   all_radiationData : cell 数组，每个元素包含至少：
    %       .dirName (string)   : 当前算例名称/目录名
    %       .gmtry   (struct)   : 与 read_b2fgmtry 类似的几何结构(包含 crx, cry, bb, hx 等)
    %       .neut    (struct)   : 来自 read_ft44 的中性粒子数据 (包含 dab2)
    %
    %   domain            : 用户选择的绘图区域 (0=全域,1=EAST上偏滤器,2=EAST下偏滤器)
    %
    % 依赖函数：
    %   - read_triangle_mesh.m (读取三角网格数据)
    %   - read_ft46.m (读取fort.46文件中的三角网格密度数据)
    %   - plot3sep.m     (可选, 在图上叠加分离器/壁结构)
    %   - saveFigureWithTimestamp (本脚本中附带)
    %
    % 更新说明：
    %   - 基于 plot_Ne_neutral_density.m 和用户提供的三角网格脚本修改
    %   - 使用标准的 read_ft46 函数读取 fort.46 文件中的三角网格密度数据
    %   - 使用三角网格绘制 Ne 中性粒子密度，采用patch函数
    %   - 保持与原脚本相同的colorbar范围（1e15到1e18）
    %   - 添加全局字体大小控制参数和Times New Roman字体设置
    %   - 确保与MATLAB 2017b兼容
    % =========================================================================

    %% ========================== 全局参数设置 ================================
    fontSize = 32;          % 统一字体大小 (坐标轴/标题/颜色栏等)，增大字体
    user_defined_baseExp_neutral = 15; % 用户在此处直接指定 Ne 中性粒子密度图的 baseExp (调整为15以匹配新的下限1e15)
    
    % 用户直接指定 Ne 中性粒子密度图 colorbar 的实际物理值范围
    user_defined_actual_cmin_neutral = 1e15; % Colorbar 实际物理值下限 (调整为: 1e15)
    user_defined_actual_cmax_neutral = 1e18; % Colorbar 实际物理值上限 (保持: 1e18)

    % 检查MATLAB版本是否为2017b或更早
    isMATLAB2017b = verLessThan('matlab', '9.3'); % R2017b是9.3版本

    %% ======================== 遍历所有算例并绘图 ============================
    totalDirs = length(all_radiationData);
    for iDir = 1 : totalDirs

        % ------------------- 1) 获取当前算例数据 -------------------
        dataStruct   = all_radiationData{iDir};
        gmtry_tmp    = dataStruct.gmtry;   % 几何信息 (已在主脚本中读取并存入)
        currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注

        % ------------------- 2) 获取Ne中性粒子密度数据 -------------------
        % 强制使用 fort.46 文件中的三角网格密度数据
        fort46_file = fullfile(currentLabel, 'fort.46');

        % 强制使用 fort.46 文件中的三角网格密度数据
        if ~exist(fort46_file, 'file')
            fprintf('Error: fort.46 file not found for case %s: %s\n', currentLabel, fort46_file);
            fprintf('This script requires fort.46 file to provide triangle mesh density data.\n');
            continue;
        end

        try
            % 使用标准的 read_ft46 函数读取 fort.46 文件
            tdata = read_ft46(fort46_file);

            % 将tdata保存到基础工作空间供用户查看
            assignin('base', 'tdata_fort46', tdata);
            fprintf('Fort.46 data saved to workspace variable: tdata_fort46\n');

            if isfield(tdata, 'pdena') && size(tdata.pdena, 2) >= 2
                % 使用 fort.46 中的 Ne 中性密度数据（第2列对应Ne中性原子）
                triangle_density_direct = tdata.pdena(:, 2);

                % 也将密度数据保存到基础工作空间
                assignin('base', 'triangle_density_Ne', triangle_density_direct);

                fprintf('Successfully read Ne neutral density from fort.46 for case %s\n', currentLabel);
                fprintf('Triangle density data: %d points, range [%.2e, %.2e] m^-3\n', ...
                        length(triangle_density_direct), min(triangle_density_direct), max(triangle_density_direct));
            else
                fprintf('Error: pdena data not found or insufficient columns in fort.46 for case %s\n', currentLabel);
                continue;
            end
        catch ME
            fprintf('Error: Failed to read fort.46 for case %s: %s\n', currentLabel, ME.message);
            fprintf('Please check the fort.46 file format and content.\n');
            continue;
        end

        % ------------------- 3) 读取三角网格数据 -------------------
        triangles = [];
        try
            % 尝试从算例目录读取三角网格文件
            caseDirPath = currentLabel;

            % 定义需要查找的三角网格文件
            triangleFiles = {'fort.33', 'fort.34', 'fort.35'};
            triangleFilePaths = cell(1, 3);
            allFilesFound = true;

            % 逐个查找三角网格文件
            for iFile = 1:length(triangleFiles)
                fileName = triangleFiles{iFile};
                filePath = fullfile(caseDirPath, fileName);

                % 检查文件是否存在（包括符号链接）
                if exist(filePath, 'file')
                    triangleFilePaths{iFile} = filePath;
                    fprintf('Found %s: %s\n', fileName, filePath);
                else
                    fprintf('Warning: %s not found in %s\n', fileName, caseDirPath);
                    allFilesFound = false;
                    break;
                end
            end

            % 如果所有文件都找到，则读取三角网格数据
            if allFilesFound
                triangles = read_triangle_mesh(triangleFilePaths{1}, triangleFilePaths{2}, triangleFilePaths{3});
                fprintf('Successfully read triangle mesh data for case %s\n', currentLabel);
            else
                fprintf('Warning: Not all triangle mesh files found for case %s. Skipping triangular mesh plot.\n', currentLabel);
                continue;
            end
        catch ME
            fprintf('Warning: Failed to read triangle mesh for case %s: %s. Skipping plot.\n', currentLabel, ME.message);
            continue;
        end

        % ------------------- 4) 准备三角网格绘图数据 -------------------
        [num_triangle, ~] = size(triangles.cells(:,1));
        A = [triangles.nodes(triangles.cells(:,1),:)];
        B = [triangles.nodes(triangles.cells(:,2),:)];
        C = [triangles.nodes(triangles.cells(:,3),:)];
        x1=A(:,1); y1=A(:,2);  x2=B(:,1); y2=B(:,2);  x3=C(:,1); y3=C(:,2);
        X_center = mean([x1,x2,x3],2);
        Y_center = mean([y1,y2,y3],2);

        % ------------------- 5) 创建图窗并设置全局字体 -------------------
        figName = sprintf('Ne Neutral Density (Triangle Mesh): %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'Units','pixels','Position',[100 50 1600 1200]); % 预设大图尺寸
        
        % 设置全局字体为Times New Roman(使用更兼容的方式)
        set(gcf, 'DefaultTextFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        
        % 设置坐标轴和文本字体大小
        set(gcf, 'DefaultAxesFontSize', fontSize);
        set(gcf, 'DefaultTextFontSize', fontSize);
        
        hold on;

        % ------------------- 6) 处理密度数据并绘制三角网格 -------------------
        % 使用 fort.46 中的三角网格数据（通过标准 read_ft46 函数读取）
        triangle_density = triangle_density_direct;

        % 检查数据有效性
        if any(triangle_density <= 0)
            fprintf('Warning: Some Ne neutral density values are non-positive in fort.46 for case %s\n', currentLabel);
            triangle_density = max(triangle_density, eps); % 将非正值设为极小正值
        end

        % 检查数据长度是否与三角网格匹配
        if length(triangle_density) ~= num_triangle
            fprintf('Error: Triangle density data length (%d) does not match triangle count (%d) for case %s\n', ...
                    length(triangle_density), num_triangle, currentLabel);
            if ishandle(gcf); close(gcf); end
            continue;
        end

        triangle_density_log = log10(triangle_density);
        fprintf('Using fort.46 triangle mesh density data (via read_ft46) for case %s\n', currentLabel);

        % (6.3) 绘制三角网格patch
        X = [x1'; x2'; x3'];  Y = [y1'; y2'; y3'];
        % 使用实际密度值作为Z，这样鼠标悬停时显示的是真实的物理值
        Z = repmat(triangle_density', 3, 1);
        
        % 设置colormap和颜色范围
        num_c = 64;  cmap = jet(num_c);  
        crange_log = [log10(user_defined_actual_cmin_neutral), log10(user_defined_actual_cmax_neutral)];
        
        % 计算颜色索引
        id_color = round((triangle_density_log - crange_log(1)) ./ (crange_log(2) - crange_log(1)) .* num_c);
        id_color(id_color < 1) = 1;  
        id_color(id_color > num_c) = num_c;  
        id_color(isnan(id_color)) = 1;
        
        % 创建颜色矩阵
        C = zeros(num_triangle, 1, 3);
        for i = 1:3
            C(:, 1, i) = cmap(id_color, i);
        end
        
        % 绘制填充的三角形
        patch(X, Y, Z, C, 'LineStyle', 'none');  % 绘制数据
        patch(X, Y, Z, C, 'LineWidth', 0.5, 'FaceAlpha', 0);  % 绘制三角网格线
        
        colormap(cmap);

        % ------------------- 7) 设置colorbar -------------------
        h_colorbar = colorbar;

        % 设置颜色范围（使用caxis以确保兼容性）
        caxis(crange_log);
        
        % 创建5个均匀分布的刻度
        logTicks = linspace(crange_log(1), crange_log(2), 5);
        baseExp = user_defined_baseExp_neutral;
        
        % 为MATLAB 2017b兼容设置colorbar属性
        if isMATLAB2017b
            % MATLAB 2017b兼容方式
            set(h_colorbar, 'Ticks', logTicks);
            
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                coefficient = 10^(logTicks(i) - baseExp);
                if abs(coefficient - round(coefficient)) < 1e-10
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            set(h_colorbar, 'TickLabels', tickLabels);
            
            set(h_colorbar, 'FontName', 'Times New Roman');
            set(h_colorbar, 'FontSize', fontSize-6);
            set(h_colorbar, 'LineWidth', 1.5);
            
            ylabel(h_colorbar, 'Ne Neutral Density [m$^{-3}$]', ...
                   'Interpreter', 'latex', ...
                   'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
            
            text(0.5, 1.05, ['{\\times}10^{', num2str(baseExp), '}'], ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
        else
            % 新版MATLAB设置方式
            h_colorbar.Ticks = logTicks;
            
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                coefficient = 10^(logTicks(i) - baseExp);
                if abs(coefficient - round(coefficient)) < 1e-10
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            h_colorbar.TickLabels = tickLabels;
            
            expStr = ['$\times 10^{', num2str(baseExp), '}$']; 
            title(h_colorbar, expStr, 'FontSize', fontSize-2, 'Interpreter', 'latex', 'FontWeight', 'bold');
            
            h_colorbar.Label.Interpreter = 'latex'; 
            h_colorbar.Label.String = 'Ne Neutral Density [m$^{-3}$]'; 
            h_colorbar.Label.FontSize = fontSize-2;
            h_colorbar.Label.FontWeight = 'bold';
            
            h_colorbar.FontName = 'Times New Roman';
            h_colorbar.FontSize = fontSize-6;
            h_colorbar.LineWidth = 1.5;
        end
        
        % ------------------- 8) 叠加分离器/结构 (可选) -------------------
        % 检测分离器配置并选择合适的绘制函数
        if gmtry_tmp.nncut==1
            fprintf('\tassumed SN\n');
            func_sep = str2func('plot3sep');
        elseif gmtry_tmp.nncut==2  && gmtry_tmp.topcut(1)>gmtry_tmp.topcut(2)
            fprintf('\tassumed DDN-up\n');
            func_sep = str2func('plot3sep_DDNup');
        elseif gmtry_tmp.nncut==2  && gmtry_tmp.topcut(1)<gmtry_tmp.topcut(2)
            fprintf('\tassumed DDN-down\n');
            func_sep = str2func('plot3sep_DDNdown');
        else
            % 默认使用标准分离器函数
            func_sep = str2func('plot3sep');
        end

        % 绘制分离器
        func_sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

        % ------------------- 9) 设置标题及坐标轴标签 -------------------
        xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');

        % ------------------- 10) 设置坐标轴属性 -------------------
        axis equal tight; 
        box on;
        grid on;
        set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5); 

        % ------------------- 11) 根据 domain 裁剪绘制区域 -------------------
        if domain~=0
            switch domain
                case 1  % 上偏滤器示例区域
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2  % 下偏滤器示例区域
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end

            if isfield(dataStruct, 'structure')
                plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        
        % ------------------- 12) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp(sprintf('Ne_Neutral_Density_Triangle_logScale_%s', currentLabel)); 

        hold off;
    end % 结束 iDir 循环

    fprintf('\n>>> Completed: Ne Neutral Density (triangular mesh, log scale) distributions for all cases.\n');

end % 主函数结束





%% =========================================================================
%% (B) 带时间戳保存图窗 (子函数保持不变)
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 说明：
    %   - 保存为.fig和.png格式，文件名包含生成时间戳
    %   - 自动调整窗口尺寸避免裁剪

    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','pixels','Position',[100 50 1600 1200]); 
    set(gcf,'PaperPositionMode','auto'); % 确保打印/保存时使用屏幕尺寸
    
    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    
    % 替换文件名中的非法字符，例如来自 currentLabel 的 ':'
    safeBaseNameFromInput = regexprep(baseName, '[\\/:\*\\?"<>\\|]', '_');
    
    finalSafeBaseName = safeBaseNameFromInput; % 默认为原始处理后的名称

    % 定义一个保守的最大总文件名长度 (例如 250 字符)
    % 常见操作系统的文件名限制大约在 255-260 字符。
    maxTotalFilenameLength = 250;
    
    % 文件名结构为: finalSafeBaseName_timestamp.fig
    % timestampStr (yyyymmdd_HHMMSS) 长度为 15
    % 额外字符: '_' (1) + '.fig' (4) = 5 字符
    maxLengthForBasePart = maxTotalFilenameLength - length(timestampStr) - 5; % finalSafeBaseName 的最大长度

    if length(safeBaseNameFromInput) > maxLengthForBasePart
        if maxLengthForBasePart <= 0 % 理论上不应发生，除非 maxTotalFilenameLength 设置得极小
            fprintf('关键错误: 文件名规则导致基本名称部分长度不足。无法安全生成文件名。\\n');
            % 创建一个极简的回退名称，应保证安全
            rand_id = char(randi([97,122],1,5)); % 5个随机小写字母
            finalSafeBaseName = ['fname_err_',rand_id];
        else
            startIndex = length(safeBaseNameFromInput) - maxLengthForBasePart + 1;
            finalSafeBaseName = safeBaseNameFromInput(startIndex:end);
            fprintf('警告: 生成的文件名基本部分过长 (原始长度 %d)，已截断为 %d 字符以适应限制。\\n', ...
                    length(safeBaseNameFromInput), length(finalSafeBaseName));
            % 显示截断后基本部分的末尾（最多50个字符），帮助用户识别
            fprintf('    截断后的基本部分 (末尾): ...%s\\n', finalSafeBaseName(max(1,end-min(length(finalSafeBaseName)-1,49)):end));
        end
    end

    % 保存.fig格式(用于后续编辑)
    figFile = sprintf('%s_%s.fig', finalSafeBaseName, timestampStr);
    try
        savefig(gcf, figFile); % 使用 gcf 获取当前图窗句柄
        fprintf('MATLAB图形文件已保存: %s\\n', figFile);
    catch ME_fig
        fprintf('保存 FIG 文件失败: %s\\n错误: %s\\n', figFile, ME_fig.message);
    end
    
    % 保存为.png格式 (用于报告或展示)
    % 如果启用PNG保存，同样需要使用 finalSafeBaseName
%     pngFile = sprintf('%s_%s.png', finalSafeBaseName, timestampStr);
%     try
%         print(gcf, pngFile, '-dpng', '-r300'); % 指定分辨率为300 DPI
%         fprintf('PNG图像文件已保存: %s\\n', pngFile);
%     catch ME_png
%         fprintf('保存 PNG 文件失败: %s\\n错误: %s\\n', pngFile, ME_png.message);
%     end
end



