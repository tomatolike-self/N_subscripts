function plot_Ne_plus_ionization_source(all_radiationData, domain)
    % =========================================================================
    % 功能：
    %   针对每个算例(已在 all_radiationData 中存有 gmtry/plasma 等信息)，在 2D 平面上绘制：
    %     1) Ne1+ 至 Ne10+ 各价态电离源分布 (ionSource2D_Ne_ion) - **分别绘制，使用对数标尺显示**
    %
    % 输入参数：
    %   all_radiationData : cell 数组，每个元素包含至少：
    %       .dirName (string)   : 当前算例名称/目录名
    %       .gmtry   (struct)   : 与 read_b2fgmtry 类似的几何结构(包含 crx, cry, bb, hx 等)
    %       .plasma  (struct)   : 与 read_b2fplasmf 类似的等离子体数据(包含 na, fna_mdf, sna 等)
    %
    %   domain            : 用户选择的绘图区域 (0=全域,1=EAST上偏滤器,2=EAST下偏滤器)
    %
    % 依赖函数：
    %   - surfplot.m     (外部已存在的绘图函数)
    %   - plot3sep.m     (可选, 在图上叠加分离器/壁结构)
    %   - compute_Ne_ionSource_for_charge_state (本脚本中附带)
    %   - saveFigureWithTimestamp       (本脚本中附带)
    %
    % 更新说明：
    %   - 基于 plot_ionization_source_and_poloidal_stagnation_point.m 修改
    %   - 绘制 Ne1+ 至 Ne10+ 各价态的电离源，移除极向速度和停滞点相关内容
    %   - 添加全局字体大小控制参数和Times New Roman字体设置
    %   - 优化颜色栏显示，将10^x作为整体后缀放在colorbar上方
    %   - 修改colorbar显示为5个刻度值，使用科学计数法
    %   - 增大字体和线宽，提高可读性和辨识度
    %   - 改进标签文本，使用LaTeX格式显示数学符号
    %   - 确保与MATLAB 2017b兼容
    % =========================================================================

    %% ========================== 全局参数设置 ================================
    fontSize = 32;          % 统一字体大小 (坐标轴/标题/颜色栏等)，增大字体
    % user_defined_baseExp = 19; % 用户在此处直接指定 baseExp 的值 % 注释掉或删除此行
    
    % 检查MATLAB版本是否为2017b或更早
    isMATLAB2017b = verLessThan('matlab', '9.3'); % R2017b是9.3版本

    %% ======================== 遍历所有算例并绘图 ============================
    totalDirs = length(all_radiationData);
    for iDir = 1 : totalDirs

        % ------------------- 1) 获取当前算例数据 -------------------
        dataStruct   = all_radiationData{iDir};
        gmtry_tmp    = dataStruct.gmtry;   % 几何信息 (已在主脚本中读取并存入)
        plasma_tmp   = dataStruct.plasma;  % 等离子体信息 (同上)
        currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注

        % --- 新增: 初始化用于统计分离面内总电离源的变量 ---
        total_ion_source_inside_sep = 0;
        [nx, ny, ~] = size(gmtry_tmp.crx);
        total_ionSource2D_Ne = zeros(nx, ny); % 初始化总电离源矩阵
        nx_plot = nx - 2;

        % 分离面径向网格编号为13 (去掉保护网格后), 对应原始网格为14.
        % 因此分离面内侧的范围是径向 2~13.
        radial_indices = 2:13;

        % 根据参考脚本 plot_separatrix_flux_comparison_grouped.m 修正极向网格范围
        % 该脚本定义主SOL/芯部区域为 plot grid 的 25 到 72 (对应96网格的典型值).
        poloidal_plot_start_ix = 25;
        poloidal_plot_end_ix = 72;
        
        actual_poloidal_plot_start = max(1, poloidal_plot_start_ix);
        actual_poloidal_plot_end = min(nx_plot, poloidal_plot_end_ix);

        % 转换为原始网格索引 (plot_grid_index + 1)
        poloidal_indices = [];
        if actual_poloidal_plot_start <= actual_poloidal_plot_end
            poloidal_indices = (actual_poloidal_plot_start:actual_poloidal_plot_end) + 1;
        end

        for chargeState = 1:10 % 循环遍历Ne1+到Ne10+

            % ------------------- 2) 计算NeZ+电离源 -------------------
            ionSource2D_Ne_ion = compute_Ne_ionSource_for_charge_state(plasma_tmp, gmtry_tmp, chargeState);
            total_ionSource2D_Ne = total_ionSource2D_Ne + ionSource2D_Ne_ion; % 累加总电离源

            % --- 新增: 统计分离面内的总电离源 (所有价态累加) ---
            if ~isempty(poloidal_indices) && ny >= max(radial_indices)
                % 将电离源密度(m-3s-1)乘以单元体积(m3)得到粒子数(s-1)
                ion_source_particles_2d = ionSource2D_Ne_ion .* gmtry_tmp.vol;
                
                % 对指定区域内的粒子源进行求和
                sum_for_current_charge_state = sum(ion_source_particles_2d(poloidal_indices, radial_indices), 'all');
                
                % 累加到总和
                total_ion_source_inside_sep = total_ion_source_inside_sep + sum_for_current_charge_state;
            end

            % ------------------- 3) 创建图窗并设置全局字体 -------------------
            figName = sprintf('Ne%d+ IonSource: %s', chargeState, currentLabel);
            figure('Name', figName, 'NumberTitle','off', 'Color','w',...
                   'Units','pixels','Position',[100 50 1600 1200]); % 预设大图尺寸
            
            % 设置全局字体为Times New Roman(使用更兼容的方式)
            set(gcf, 'DefaultTextFontName', 'Times New Roman');
            set(gcf, 'DefaultAxesFontName', 'Times New Roman');
            
            % 设置坐标轴和文本字体大小
            set(gcf, 'DefaultAxesFontSize', fontSize);
            set(gcf, 'DefaultTextFontSize', fontSize);
            
            hold on;

            % (3.0) 对电离源数据取对数 (处理小于等于 0 的值)
            ionSource2D_Ne_ion_log = log10(max(ionSource2D_Ne_ion, eps)); % 使用 eps 避免 log10(0)

            % (3.1) 调用 surfplot 绘制电离源彩色图 (使用对数数据)
            surfplot(gmtry_tmp, ionSource2D_Ne_ion_log);
            shading interp;
            view(2);
            colormap(jet);
            
            % 创建colorbar并获取句柄
            h_colorbar = colorbar;
            
            % (3.2) 根据 chargeState 设置colorbar显示范围和格式
            if chargeState <= 5 % 修改条件：1-5价
                caxis_min_log = 20; % 对应 10^20
                caxis_max_log = 22; % 对应 10^22
                baseExp = 20;       % 指数项
            else % chargeState >= 6，即6-10价
                caxis_min_log = 19; % 对应 10^19
                caxis_max_log = 21; % 对应 10^21
                baseExp = 19;       % 指数项
            end
            caxis([caxis_min_log, caxis_max_log]);
            
            % 创建5个均匀分布的刻度
            logTicks = linspace(caxis_min_log, caxis_max_log, 5);
            
            % 提取最小指数值作为基准指数
            % baseExp = floor(caxis_min_log); % 或者选择一个合适的固定基准 % 注释掉原来的计算方式
            % baseExp = user_defined_baseExp; % 使用上面条件设定的 baseExp
            
            % 为MATLAB 2017b兼容设置colorbar属性
            if isMATLAB2017b
                % MATLAB 2017b兼容方式
                set(h_colorbar, 'Ticks', logTicks);
                
                % 根据指数范围创建刻度标签
                tickLabels = cell(length(logTicks), 1);
                for i = 1:length(logTicks)
                    % 计算相对于基准指数的系数
                    coefficient = 10^(logTicks(i) - baseExp);
                    
                    % 以紧凑的格式显示系数（最多一位小数）
                    if abs(coefficient - round(coefficient)) < 1e-10
                        % 系数是整数，不显示小数点
                        tickLabels{i} = sprintf('%d', round(coefficient));
                    else
                        % 系数不是整数，显示一位小数
                        tickLabels{i} = sprintf('%.1f', coefficient);
                    end
                end
                
                % 应用刻度标签
                set(h_colorbar, 'TickLabels', tickLabels);
                
                % 设置colorbar属性
                set(h_colorbar, 'FontName', 'Times New Roman');
                set(h_colorbar, 'FontSize', fontSize-6);
                set(h_colorbar, 'LineWidth', 1.5);
                
                % 设置colorbar标签
                ylabel(h_colorbar, sprintf('Ne$^{{%d+}}$ Ionization Source [m$^{-3}$s$^{-1}$]', chargeState), ...
                       'Interpreter', 'latex', ... % 明确指定解释器
                       'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
                
                % 在colorbar上方添加指数部分
                text(0.5, 1.05, ['{\\times}10^{', num2str(baseExp), '}'], ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                    'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
            else
                % 新版MATLAB设置方式
                h_colorbar.Ticks = logTicks;
                
                % 根据指数范围创建刻度标签
                tickLabels = cell(length(logTicks), 1);
                for i = 1:length(logTicks)
                    % 计算相对于基准指数的系数
                    coefficient = 10^(logTicks(i) - baseExp);
                    
                    % 以紧凑的格式显示系数（最多一位小数）
                    if abs(coefficient - round(coefficient)) < 1e-10
                        % 系数是整数，不显示小数点
                        tickLabels{i} = sprintf('%d', round(coefficient));
                    else
                        % 系数不是整数，显示一位小数
                        tickLabels{i} = sprintf('%.1f', coefficient);
                    end
                end
                
                % 应用刻度标签
                h_colorbar.TickLabels = tickLabels;
                
                % 在colorbar上方添加指数部分作为标题
                % 使用latex格式确保数学符号正确显示
                expStr = ['$\times 10^{', num2str(baseExp), '}$']; % 移除 $ 和 \mathbf, 添加 $ 包围
                title(h_colorbar, expStr, 'FontSize', fontSize-2, 'Interpreter', 'latex', 'FontWeight', 'bold'); % 添加 FontWeight
                
                % 修改标签文本
                h_colorbar.Label.Interpreter = 'latex'; % 先设置解释器
                h_colorbar.Label.String = sprintf('Ne$^{{%d+}}$ Ionization Source [m$^{-3}$s$^{-1}$]', chargeState); % 修改sprintf格式
                h_colorbar.Label.FontSize = fontSize-2;
                h_colorbar.Label.FontWeight = 'bold';
                
                % 设置colorbar属性
                h_colorbar.FontName = 'Times New Roman';
                h_colorbar.FontSize = fontSize-6;
                h_colorbar.LineWidth = 1.5;  % 增加线宽
            end
            
            % (3.3) 叠加分离器/结构 (可选)
            plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

            % (3.4) 设置标题及坐标轴标签
            % title(sprintf('Log_{10}(Ne%d+ Ionization Source)', chargeState),'FontSize', fontSize+2); % 标题稍大
            xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
            ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');

            % (3.5) 设置坐标轴属性
            axis equal tight; % 合并等效命令
            box on;
            grid on;
            set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5); % 确保坐标轴字体应用统一设置

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
            end
            
            % 添加结构绘制
            if isfield(dataStruct, 'structure')
                plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
            end
            
            % ------------------- 5) 保存带时间戳的图窗 -------------------
            saveFigureWithTimestamp(sprintf('Ne%dplus_IonSource_logScale', chargeState)); 

            hold off;
        end % 结束 chargeState 循环

        % --- 新增: 绘制 Ne 1+ 到 10+ 电离源分布总和 ---
        figName = sprintf('Total Ne IonSource: %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'Units','pixels','Position',[100 50 1600 1200]);
        
        % 设置全局字体为Times New Roman(使用更兼容的方式)
        set(gcf, 'DefaultTextFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        
        % 设置坐标轴和文本字体大小
        set(gcf, 'DefaultAxesFontSize', fontSize);
        set(gcf, 'DefaultTextFontSize', fontSize);
        
        hold on;

        % (3.0) 对总电离源数据取对数
        total_ionSource2D_Ne_log = log10(max(total_ionSource2D_Ne, eps));

        % (3.1) 调用 surfplot 绘制电离源彩色图 (使用对数数据)
        surfplot(gmtry_tmp, total_ionSource2D_Ne_log);
        shading interp;
        view(2);
        colormap(jet);
        
        % 创建colorbar并获取句柄
        h_colorbar = colorbar;
        
        % (3.2) 设置总源的色轴范围和格式
        % 注意: 这个范围可能需要根据实际结果进行微调
        caxis_min_log = 19; 
        caxis_max_log = 22; 
        baseExp = 19;
        caxis([caxis_min_log, caxis_max_log]);
        
        % 创建5个均匀分布的刻度
        logTicks = linspace(caxis_min_log, caxis_max_log, 5);
        
        % 为MATLAB 2017b兼容设置colorbar属性
        if isMATLAB2017b
            % MATLAB 2017b兼容方式
            set(h_colorbar, 'Ticks', logTicks);
            
            % 根据指数范围创建刻度标签
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                % 计算相对于基准指数的系数
                coefficient = 10^(logTicks(i) - baseExp);
                
                % 以紧凑的格式显示系数（最多一位小数）
                if abs(coefficient - round(coefficient)) < 1e-10
                    % 系数是整数，不显示小数点
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    % 系数不是整数，显示一位小数
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            
            % 应用刻度标签
            set(h_colorbar, 'TickLabels', tickLabels);
            
            % 设置colorbar属性
            set(h_colorbar, 'FontName', 'Times New Roman');
            set(h_colorbar, 'FontSize', fontSize-6);
            set(h_colorbar, 'LineWidth', 1.5);
            
            % 设置colorbar标签
            ylabel(h_colorbar, 'Total Ne Ionization Source [m$^{-3}$s$^{-1}$]', ...
                   'Interpreter', 'latex', ...
                   'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
            
            % 在colorbar上方添加指数部分
            text(0.5, 1.05, ['{\\times}10^{', num2str(baseExp), '}'], ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
        else
            % 新版MATLAB设置方式
            h_colorbar.Ticks = logTicks;
            
            % 根据指数范围创建刻度标签
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                % 计算相对于基准指数的系数
                coefficient = 10^(logTicks(i) - baseExp);
                
                % 以紧凑的格式显示系数（最多一位小数）
                if abs(coefficient - round(coefficient)) < 1e-10
                    % 系数是整数，不显示小数点
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    % 系数不是整数，显示一位小数
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            
            % 应用刻度标签
            h_colorbar.TickLabels = tickLabels;
            
            % 在colorbar上方添加指数部分作为标题
            expStr = ['$\times 10^{', num2str(baseExp), '}$'];
            title(h_colorbar, expStr, 'FontSize', fontSize-2, 'Interpreter', 'latex', 'FontWeight', 'bold');
            
            % 修改标签文本
            h_colorbar.Label.Interpreter = 'latex';
            h_colorbar.Label.String = 'Total Ne Ionization Source [m$^{-3}$s$^{-1}$]';
            h_colorbar.Label.FontSize = fontSize-2;
            h_colorbar.Label.FontWeight = 'bold';
            
            % 设置colorbar属性
            h_colorbar.FontName = 'Times New Roman';
            h_colorbar.FontSize = fontSize-6;
            h_colorbar.LineWidth = 1.5;
        end
        
        % (3.3) 叠加分离器/结构
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

        % (3.4) 设置坐标轴标签
        xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');

        % (3.5) 设置坐标轴属性
        axis equal tight;
        box on;
        grid on;
        set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5);

        % (3.6) 根据 domain 裁剪绘制区域
        if domain~=0
            switch domain
                case 1
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end
        end
        
        % 添加结构绘制
        if isfield(dataStruct, 'structure')
            plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
        end
        
        % (3.7) 保存带时间戳的图窗
        saveFigureWithTimestamp('Total_Ne_IonSource_logScale');
        hold off;

        % --- 新增: 打印当前算例的统计结果 ---
        fprintf('\n----------------- Statistics for Case: %s -----------------\n', currentLabel);
        % 检查径向网格数和极向网格范围是否有效
        if ~isempty(poloidal_indices) && ny >= 13
             fprintf('Total Ne ionization source inside separatrix (core region, ix=%d:%d, iy=%d:%d): %.4e particles/s\n', ...
                poloidal_indices(1), poloidal_indices(end), radial_indices(1), radial_indices(end), total_ion_source_inside_sep);
        else
            if ny < 13
                fprintf('Grid size (ny=%d) is too small to calculate ionization source inside separatrix (requires ny>=13).\n', ny);
            end
            if isempty(poloidal_indices)
                 fprintf('Poloidal grid range for core region is not valid for this grid size (nx=%d).\n', nx);
            end
        end
        fprintf('-----------------------------------------------------------------\n\n');

    end % 结束 iDir 循环

    fprintf('\n>>> Completed: Ne1+ to Ne10+ Ionization source (log scale) distributions for all cases.\n');

end % 主函数结束


%% =========================================================================
%% (A) 计算二维NeZ+电离源分布
%% =========================================================================
function ionSource2D_Ne_ion = compute_Ne_ionSource_for_charge_state(plasma_tmp, gmtry_tmp, chargeState)
    % 说明：
    %   - 电离源计算基于等离子体源项(sna)和密度(na)数据, 针对指定的Ne价态
    % 输入参数:
    %   plasma_tmp  : 等离子体数据结构体
    %   gmtry_tmp   : 几何数据结构体
    %   chargeState : 整数, 1 代表 Ne1+, 2 代表 Ne2+, ..., 10 代表 Ne10+

    [nx, ny, ~] = size(gmtry_tmp.crx); % 假设 crx 定义了网格维度
    ionSource2D_Ne_ion = zeros(nx, ny);

    % 确定对应Ne Z+的组分索引 (iComp_Ne_ion)
    % 假设：杂质的第一个电离态(如Ne1+)在EIRENE输出中通常是species_idx=4 (紧随 D0, D+, e-)
    % 因此 Ne(Z)+ 对应索引 3 + Z
    iComp_Ne_ion = 3 + chargeState;
    
    % 检查计算出的 species index 是否在 plasma_tmp.sna 和 plasma_tmp.na 的有效范围内
    species_index_is_valid = ...
        isfield(plasma_tmp, 'sna') && ndims(plasma_tmp.sna) >= 4 && iComp_Ne_ion <= size(plasma_tmp.sna, 4) && ...
        isfield(plasma_tmp, 'na') && ndims(plasma_tmp.na) >= 3 && iComp_Ne_ion <= size(plasma_tmp.na, 3);

    % 仅当物种索引有效时才执行计算
    if species_index_is_valid
        for jPos = 1 : ny
            for iPos = 1 : nx
                % ----- Ne Z+ 电离源计算 -----
                coeff0_Ne_ion = plasma_tmp.sna(iPos, jPos, 1, iComp_Ne_ion);
                coeff1_Ne_ion = plasma_tmp.sna(iPos, jPos, 2, iComp_Ne_ion);
                n_Ne_ion      = plasma_tmp.na(iPos, jPos, iComp_Ne_ion);
                sVal_Ne_ion   = coeff0_Ne_ion + coeff1_Ne_ion * n_Ne_ion;
                
                % 单元体积归一化，并检查vol字段和值的有效性
                if isfield(gmtry_tmp, 'vol') && ...
                   iPos <= size(gmtry_tmp.vol,1) && jPos <= size(gmtry_tmp.vol,2) && ...
                   gmtry_tmp.vol(iPos, jPos) > 0
                    ionSource2D_Ne_ion(iPos, jPos) = sVal_Ne_ion / gmtry_tmp.vol(iPos, jPos);
                else
                    ionSource2D_Ne_ion(iPos, jPos) = 0; % 如果体积无效或为零，则源为零
                end
            end
        end
    end
    % 如果物种索引无效，函数将返回初始化的零矩阵，确保尺寸正确。
end


%% =========================================================================
%% (B) 带时间戳保存图窗 (子函数保持不变)
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 说明：
    %   - 保存为.fig格式，文件名包含生成时间戳
    %   - 自动调整窗口尺寸避免裁剪

    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','pixels','Position',[100 50 1600 1200]); % 增大图像尺寸
    set(gcf,'PaperPositionMode','auto');
    
    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    
    % 保存.fig格式(用于后续编辑)
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    fprintf('MATLAB图形文件已保存: %s\n', figFile);
    
end 