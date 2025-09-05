function plot_Ne_neutral_density(all_radiationData, domain)
    % =========================================================================
    % 功能：
    %   针对每个算例(已在 all_radiationData 中存有 gmtry/neut 等信息)，在 2D 平面上绘制：
    %     1) Ne 中性粒子密度分布 (来自 neut.dab2(:,:,2)) - **使用对数标尺显示**
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
    %   - surfplot.m     (外部已存在的绘图函数)
    %   - plot3sep.m     (可选, 在图上叠加分离器/壁结构)
    %   - saveFigureWithTimestamp (本脚本中附带)
    %
    % 更新说明：
    %   - 基于 plot_Ne_plus_ionization_source.m 修改
    %   - 绘制 Ne 中性粒子密度，移除电离源和极向速度相关内容
    %   - 添加全局字体大小控制参数和Times New Roman字体设置
    %   - 优化颜色栏显示，将10^x作为整体后缀放在colorbar上方
    %   - 修改colorbar显示为5个刻度值，使用科学计数法
    %   - 增大字体和线宽，提高可读性和辨识度
    %   - 改进标签文本，使用LaTeX格式显示数学符号
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

        % ------------------- 2) 获取Ne中性粒子密度 -------------------
        if isfield(dataStruct, 'neut') && isfield(dataStruct.neut, 'dab2') && size(dataStruct.neut.dab2,3) >= 2
            neutral_Ne_density_2D = dataStruct.neut.dab2(:,:,2); % 第二个索引对应Ne中性原子
            % 确保数据是二维的 (nx, ny)
            if ndims(neutral_Ne_density_2D) == 3 && size(neutral_Ne_density_2D,3) == 1
                neutral_Ne_density_2D = squeeze(neutral_Ne_density_2D);
            elseif ndims(neutral_Ne_density_2D) ~= 2
                 fprintf('Warning: neutral_Ne_density_2D is not 2D for case %s. Skipping plot.\n', currentLabel);
                 continue;
            end
        else
            fprintf('Warning: neut.dab2(:,:,2) not found or is not as expected for case %s. Skipping plot for this case.\n', currentLabel);
            continue; 
        end

        % ------------------- 3) 创建图窗并设置全局字体 -------------------
        figName = sprintf('Ne Neutral Density: %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'Units','pixels','Position',[100 50 1600 1200]); % 预设大图尺寸
        
        % 设置全局字体为Times New Roman(使用更兼容的方式)
        set(gcf, 'DefaultTextFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        
        % 设置坐标轴和文本字体大小
        set(gcf, 'DefaultAxesFontSize', fontSize);
        set(gcf, 'DefaultTextFontSize', fontSize);
        
        hold on;

        % (3.0) 对中性Ne密度数据取对数 (处理小于等于 0 的值)
        neutral_Ne_density_2D_positive = neutral_Ne_density_2D(neutral_Ne_density_2D > 0);
        if isempty(neutral_Ne_density_2D_positive)
            fprintf('Warning: All Ne neutral density values are non-positive for case %s. Skipping plot.\n', currentLabel);
            if ishandle(gcf); close(gcf); end % 关闭已创建的空图窗
            continue;
        end
        neutral_Ne_density_2D_log = log10(max(neutral_Ne_density_2D, eps)); % 使用 eps 避免 log10(0)

        % (3.1) 调用 surfplot 绘制电离源彩色图 (使用对数数据)
        surfplot(gmtry_tmp, neutral_Ne_density_2D_log);
        shading interp;
        view(2);
        colormap(jet);
        
        % 创建colorbar并获取句柄
        h_colorbar = colorbar;
        
        % (3.2) 设置colorbar显示范围和格式
        % 从用户定义的实际物理值计算对数刻度范围
        caxis_min_log = log10(user_defined_actual_cmin_neutral); 
        caxis_max_log = log10(user_defined_actual_cmax_neutral); 
        caxis([caxis_min_log, caxis_max_log]);
        
        % 创建5个均匀分布的刻度
        logTicks = linspace(caxis_min_log, caxis_max_log, 5);
        
        baseExp = user_defined_baseExp_neutral; % 使用为此脚本定义的 baseExp
        
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
        
        % (3.3) 叠加分离器/结构 (可选)
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

        % (3.4) 设置标题及坐标轴标签
        % title('Log_{10}(Ne Neutral Density)','FontSize', fontSize+2); % 可选，如果需要主标题
        xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');

        % (3.5) 设置坐标轴属性
        axis equal tight; 
        box on;
        grid on;
        set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5); 

        % ------------------- 4) 根据 domain 裁剪绘制区域 -------------------
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
        
        % ------------------- 5) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp(sprintf('Ne_Neutral_Density_logScale_%s', currentLabel)); 

        hold off;
    end % 结束 iDir 循环

    fprintf('\n>>> Completed: Ne Neutral Density (log scale) distributions for all cases.\n');

end % 主函数结束


%% =========================================================================
%% (A) 带时间戳保存图窗 (子函数保持不变)
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