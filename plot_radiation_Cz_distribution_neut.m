function plot_radiation_Cz_distribution(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制三组算例的辐射分布和杂质浓度分布对比图。
    %       第1行显示总辐射分布，第2行显示Ne杂质辐射分布，第3行显示杂质浓度分布。
    %       每组算例在子图左上角添加标识（favorable B_T，unfavorable B_T，w/o drift）。
    %       同时把各算例的辐射信息输出到一个带时间后缀的 .txt 文件中。
    %       绘图后会自动保存 .fig 文件，文件名包含时间后缀，避免互相覆盖。
    %       对辐射分布使用对数颜色标尺，但标尺显示的是真实值而非对数值。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例辐射信息的 cell 数组
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室或偏滤器结构信息)
    %       .totrad_ns       (matrix) - 总辐射分布
    %       .totrad_Ne       (matrix) - Ne杂质辐射分布
    %       .plasma.na       (matrix) - 杂质密度数据，na(:,:,3:13)为Ne0到Ne10+
    %       .plasma.ne       (matrix) - 电子密度数据
    %   3) MATLAB 版本需要支持 savefig 等功能。
    % =========================================================================
    
    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', 16);
    set(0, 'DefaultLineLineWidth', 1.5);
    
    % 确保输入数据是3组算例
    if length(all_radiationData) ~= 3
        warning('This function expects 3 cases, but received %d. Will continue with the available data.', length(all_radiationData));
    end
    
    % 为三组算例分配标签
    case_labels = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
    
    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围
    all_totrad_ns_min = +Inf;   all_totrad_ns_max = -Inf;
    all_totrad_Ne_min = +Inf;   all_totrad_Ne_max = -Inf;
    all_cz_ratio_min = +Inf;    all_cz_ratio_max = -Inf;
    
    % 遍历每个算例，更新全局 min/max
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % Total radiation (no-separatrix)
        all_totrad_ns_min = min(all_totrad_ns_min, min(radInfo.totrad_ns(radInfo.totrad_ns>0)));
        all_totrad_ns_max = max(all_totrad_ns_max, max(radInfo.totrad_ns(:)));
        
        % Ne radiation (no-separatrix)
        all_totrad_Ne_min = min(all_totrad_Ne_min, min(radInfo.totrad_Ne(radInfo.totrad_Ne>0)));
        all_totrad_Ne_max = max(all_totrad_Ne_max, max(radInfo.totrad_Ne(:)));
        
        % 计算杂质浓度（Ne0-Ne10+总密度 / 电子密度）
        % 获取Ne离子密度（Ne1+到Ne10+）
        n_Ne_ion = sum(radInfo.plasma.na(2:end-1,2:end-1,4:13), 3);  % Ne离子密度：Ne1+到Ne10+的总和
        
        % 获取Ne原子密度（从neut.dab2获取）
        n_Ne_atom = radInfo.neut.dab2(:,:,2);  % Ne原子密度
        
        % 计算Ne杂质核密度总和
        n_Ne_nucl = n_Ne_ion + n_Ne_atom;  % Ne核密度总和
        
        % 计算杂质浓度比例（Ne/ne）
        cz_ratio = n_Ne_nucl ./ radInfo.plasma.ne(2:end-1,2:end-1);  % 杂质浓度（Ne/ne比例）
        
        % 找出有效的杂质浓度值（避免除以零或非物理值）
        valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
        if ~isempty(valid_cz)
            all_cz_ratio_min = min(all_cz_ratio_min, min(valid_cz));
            all_cz_ratio_max = max(all_cz_ratio_max, max(valid_cz(:)));
        end
    end
    
    % 防止最小值太小导致对数标尺的问题
    all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max*1e-6);
    all_totrad_Ne_min = max(all_totrad_Ne_min, all_totrad_Ne_max*1e-6);
    
    
    %% 2) 把辐射信息输出到带时间后缀的文件中
    % 生成一个时间戳
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');
    
    % 拼接输出的 txt 文件名
    radInfoFilename = fullfile(pwd, ['radiation_cz_info_', timeSuffix, '.txt']);
    
    % 打开文件写入（若失败，则仅在屏幕打印）
    fid = fopen(radInfoFilename, 'w');
    if fid < 0
        warning('Cannot open file %s for writing. Will just print to screen.', radInfoFilename);
    end
    
    % 逐个算例打印/写入必要信息
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % 计算杂质浓度平均值和最大值
        impurity_density = sum(radInfo.plasma.na(:,:,3:13), 3);
        cz_ratio = impurity_density ./ radInfo.plasma.ne;
        valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
        avg_cz = mean(valid_cz);
        max_cz = max(valid_cz(:));
        
        % 计算Ne在内外偏滤器区域的辐射量
        Ne_totrad = sum(sum(radInfo.totrad_Ne.*radInfo.volcell))*1e-6; % Ne总辐射功率 (MW)
        
        % 获取偏滤器区域索引
        index_div = [];
        outer_div_indices = [];
        inner_div_indices = [];
        
        if isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut')
            [nxd, ~] = size(radInfo.gmtry.crx(:,:,1)); % 获取网格尺寸
            
            % 偏滤器区域索引: 1-24是外偏滤器区域，73-96是内偏滤器区域（对应96*26的网格）
            outer_div_indices = 1:radInfo.gmtry.leftcut;
            inner_div_indices = (radInfo.gmtry.rightcut+1):(nxd-2);
            index_div = [outer_div_indices, inner_div_indices];
        end
        
        % 计算Ne在内外偏滤器区域的辐射量
        Ne_outer_div_rad = 0;
        Ne_inner_div_rad = 0;
        
        if ~isempty(outer_div_indices)
            Ne_outer_div_rad = sum(sum(radInfo.totrad_Ne(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)))*1e-6;
        end
        
        if ~isempty(inner_div_indices)
            Ne_inner_div_rad = sum(sum(radInfo.totrad_Ne(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)))*1e-6;
        end
        
        % 计算Ne辐射在外偏滤器、内偏滤器和总量中的占比
        Ne_outer_div_fraction = Ne_outer_div_rad / Ne_totrad;
        Ne_inner_div_fraction = Ne_inner_div_rad / Ne_totrad;
        Ne_div_fraction = (Ne_outer_div_rad + Ne_inner_div_rad) / Ne_totrad;
        
        % 计算Ne杂质在整个计算区域的总数量（密度×体积）
        % 累加所有Ne价态 (Ne0到Ne10+) 的数量
        Ne_total_amount = 0;
        for i_Z = 3:13 % Ne0到Ne10+的索引为3到13
            % 确保使用裁剪后的数据 - na需要裁剪以匹配volcell维度
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格，与volcell匹配
            Ne_total_amount = Ne_total_amount + sum(sum(na_sliced.*radInfo.volcell));
        end
        Ne_total_amount = Ne_total_amount + sum(sum(radInfo.neut.dab2(:,:,2).*radInfo.volcell)); % Ne粒子数量，加上中性Ne原子
        
        % 计算Ne杂质在偏滤器区域的数量
        Ne_div_amount = 0;
        Ne_outer_div_amount = 0;
        Ne_inner_div_amount = 0;
        
        if ~isempty(outer_div_indices)
            for i_Z = 3:13
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                Ne_outer_div_amount = Ne_outer_div_amount + sum(sum(na_sliced(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)));
            end
            Ne_outer_div_amount = Ne_outer_div_amount + sum(sum(radInfo.neut.dab2(outer_div_indices,:,2).*radInfo.volcell(outer_div_indices,:))); % Ne粒子数量，加上中性Ne原子
        end
        
        if ~isempty(inner_div_indices)
            for i_Z = 3:13
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                Ne_inner_div_amount = Ne_inner_div_amount + sum(sum(na_sliced(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)));
            end
            Ne_inner_div_amount = Ne_inner_div_amount + sum(sum(radInfo.neut.dab2(inner_div_indices,:,2).*radInfo.volcell(inner_div_indices,:))); % Ne粒子数量，加上中性Ne原子
        end
        
        Ne_div_amount = Ne_outer_div_amount + Ne_inner_div_amount;
        
        % 计算Ne杂质在偏滤器区域的占比
        Ne_div_amount_fraction = Ne_div_amount / Ne_total_amount;
        Ne_outer_div_amount_fraction = Ne_outer_div_amount / Ne_total_amount;
        Ne_inner_div_amount_fraction = Ne_inner_div_amount / Ne_total_amount;
        
        % ------ 新增：定义主SOL层和芯部边缘区域索引 ------
        main_SOL_indices = [];
        core_edge_indices = [];
        
        if isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut') && isfield(radInfo.gmtry, 'topcut')
            % 获取分离面位置（使用topcut+1）
            j_sep = radInfo.gmtry.topcut + 1;
            
            % 主SOL层：外偏滤器区域之后到内偏滤器区域之前的区域，且在分离面外侧(j_sep+1:end)
            main_SOL_indices_x = (radInfo.gmtry.leftcut+1):(radInfo.gmtry.rightcut);
            main_SOL_indices = [];
            
            % 创建主SOL层索引矩阵（分离面外侧）
            for ix = main_SOL_indices_x
                for jy = (j_sep+1):size(radInfo.volcell, 2)
                    if ix <= size(radInfo.volcell, 1) && jy <= size(radInfo.volcell, 2)
                        main_SOL_indices = [main_SOL_indices; ix jy];
                    end
                end
            end
            
            % 芯部边缘区域：与主SOL层相同的径向位置，但在分离面内侧(1:j_sep)
            core_edge_indices = [];
            
            % 创建芯部边缘区域索引矩阵（分离面内侧）
            for ix = main_SOL_indices_x
                for jy = 1:j_sep
                    if ix <= size(radInfo.volcell, 1) && jy <= size(radInfo.volcell, 2)
                        core_edge_indices = [core_edge_indices; ix jy];
                    end
                end
            end
        end
        
        % ------ 新增：计算主SOL层的Ne粒子数和辐射量 ------
        Ne_main_SOL_amount = 0;
        Ne_main_SOL_rad = 0;
        
        if ~isempty(main_SOL_indices)
            % 计算主SOL层的Ne粒子数
            % Ne1+到Ne10+
            for i_Z = 4:13
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                for i = 1:size(main_SOL_indices, 1)
                    ix = main_SOL_indices(i, 1);
                    jy = main_SOL_indices(i, 2);
                    if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                        Ne_main_SOL_amount = Ne_main_SOL_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                    end
                end
            end
            
            % 添加中性Ne原子的贡献
            for i = 1:size(main_SOL_indices, 1)
                ix = main_SOL_indices(i, 1);
                jy = main_SOL_indices(i, 2);
                if ix <= size(radInfo.neut.dab2, 1) && jy <= size(radInfo.neut.dab2, 2)
                    Ne_main_SOL_amount = Ne_main_SOL_amount + radInfo.neut.dab2(ix, jy, 2) * radInfo.volcell(ix, jy);
                end
            end
            
            % 计算主SOL层的Ne辐射量
            for i = 1:size(main_SOL_indices, 1)
                ix = main_SOL_indices(i, 1);
                jy = main_SOL_indices(i, 2);
                if ix <= size(radInfo.totrad_Ne, 1) && jy <= size(radInfo.totrad_Ne, 2)
                    Ne_main_SOL_rad = Ne_main_SOL_rad + radInfo.totrad_Ne(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
            Ne_main_SOL_rad = Ne_main_SOL_rad * 1e-6;  % 转换为MW
        end
        
        % 计算主SOL层的Ne粒子数和辐射量占比
        Ne_main_SOL_amount_fraction = Ne_main_SOL_amount / Ne_total_amount;
        Ne_main_SOL_rad_fraction = Ne_main_SOL_rad / Ne_totrad;
        
        % ------ 新增：计算芯部边缘区域的Ne粒子数和辐射量 ------
        Ne_core_edge_amount = 0;
        Ne_core_edge_rad = 0;
        
        if ~isempty(core_edge_indices)
            % 计算芯部边缘区域的Ne粒子数
            for i_Z = 3:13
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                for i = 1:size(core_edge_indices, 1)
                    ix = core_edge_indices(i, 1);
                    jy = core_edge_indices(i, 2);
                    if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                        Ne_core_edge_amount = Ne_core_edge_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                    end
                end
            end
            
            % 添加中性Ne原子的贡献
            for i = 1:size(core_edge_indices, 1)
                ix = core_edge_indices(i, 1);
                jy = core_edge_indices(i, 2);
                if ix <= size(radInfo.neut.dab2, 1) && jy <= size(radInfo.neut.dab2, 2)
                    Ne_core_edge_amount = Ne_core_edge_amount + radInfo.neut.dab2(ix, jy, 2) * radInfo.volcell(ix, jy);
                end
            end
            
            % 计算芯部边缘区域的Ne辐射量
            for i = 1:size(core_edge_indices, 1)
                ix = core_edge_indices(i, 1);
                jy = core_edge_indices(i, 2);
                if ix <= size(radInfo.totrad_Ne, 1) && jy <= size(radInfo.totrad_Ne, 2)
                    Ne_core_edge_rad = Ne_core_edge_rad + radInfo.totrad_Ne(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
            Ne_core_edge_rad = Ne_core_edge_rad * 1e-6;  % 转换为MW
        end
        
        % 计算芯部边缘区域的Ne粒子数和辐射量占比
        Ne_core_edge_amount_fraction = Ne_core_edge_amount / Ne_total_amount;
        Ne_core_edge_rad_fraction = Ne_core_edge_rad / Ne_totrad;
    
        % 屏幕打印
        fprintf('\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
        fprintf('\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
        fprintf('\tNe radiation power:      %2.3f MW\n', Ne_totrad);
        fprintf('\tNe outer divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad, Ne_outer_div_fraction*100);
        fprintf('\tNe inner divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_inner_div_rad, Ne_inner_div_fraction*100);
        fprintf('\tNe total divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad + Ne_inner_div_rad, Ne_div_fraction*100);
        fprintf('\tNe main SOL radiation: %2.3f MW (%2.1f%%)\n', Ne_main_SOL_rad, Ne_main_SOL_rad_fraction*100);
        fprintf('\tNe core edge radiation: %2.3f MW (%2.1f%%)\n', Ne_core_edge_rad, Ne_core_edge_rad_fraction*100);
        fprintf('\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
        fprintf('\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
        fprintf('\tNe total amount: %2.3e particles\n', Ne_total_amount);
        fprintf('\tNe in outer divertor: %2.3e particles (%2.1f%%)\n', Ne_outer_div_amount, Ne_outer_div_amount_fraction*100);
        fprintf('\tNe in inner divertor: %2.3e particles (%2.1f%%)\n', Ne_inner_div_amount, Ne_inner_div_amount_fraction*100);
        fprintf('\tNe in total divertor: %2.3e particles (%2.1f%%)\n', Ne_div_amount, Ne_div_amount_fraction*100);
        fprintf('\tNe in main SOL: %2.3e particles (%2.1f%%)\n', Ne_main_SOL_amount, Ne_main_SOL_amount_fraction*100);
        fprintf('\tNe in core edge: %2.3e particles (%2.1f%%)\n', Ne_core_edge_amount, Ne_core_edge_amount_fraction*100);
        fprintf('\tAverage impurity concentration: %2.3e\n', avg_cz);
        fprintf('\tMaximum impurity concentration: %2.3e\n', max_cz);
    
        % 写入到文件
        if fid >= 0
            fprintf(fid, '\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
            fprintf(fid, '\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
            fprintf(fid, '\tNe radiation power:      %2.3f MW\n', Ne_totrad);
            fprintf(fid, '\tNe outer divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad, Ne_outer_div_fraction*100);
            fprintf(fid, '\tNe inner divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_inner_div_rad, Ne_inner_div_fraction*100);
            fprintf(fid, '\tNe total divertor radiation: %2.3f MW (%2.1f%%)\n', Ne_outer_div_rad + Ne_inner_div_rad, Ne_div_fraction*100);
            fprintf(fid, '\tNe main SOL radiation: %2.3f MW (%2.1f%%)\n', Ne_main_SOL_rad, Ne_main_SOL_rad_fraction*100);
            fprintf(fid, '\tNe core edge radiation: %2.3f MW (%2.1f%%)\n', Ne_core_edge_rad, Ne_core_edge_rad_fraction*100);
            fprintf(fid, '\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
            fprintf(fid, '\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
            fprintf(fid, '\tNe total amount: %2.3e particles\n', Ne_total_amount);
            fprintf(fid, '\tNe in outer divertor: %2.3e particles (%2.1f%%)\n', Ne_outer_div_amount, Ne_outer_div_amount_fraction*100);
            fprintf(fid, '\tNe in inner divertor: %2.3e particles (%2.1f%%)\n', Ne_inner_div_amount, Ne_inner_div_amount_fraction*100);
            fprintf(fid, '\tNe in total divertor: %2.3e particles (%2.1f%%)\n', Ne_div_amount, Ne_div_amount_fraction*100);
            fprintf(fid, '\tNe in main SOL: %2.3e particles (%2.1f%%)\n', Ne_main_SOL_amount, Ne_main_SOL_amount_fraction*100);
            fprintf(fid, '\tNe in core edge: %2.3e particles (%2.1f%%)\n', Ne_core_edge_amount, Ne_core_edge_amount_fraction*100);
            fprintf(fid, '\tAverage impurity concentration: %2.3e\n', avg_cz);
            fprintf(fid, '\tMaximum impurity concentration: %2.3e\n', max_cz);
        end
    end
    
    % 如果文件成功打开，则 fclose 并提示
    if fid >= 0
        fclose(fid);
        fprintf('\nRadiation and impurity concentration info has been written to: %s\n', radInfoFilename);
    end
    
    
    %% 3) 创建一个3行3列的子图布局，绘制所有算例的对比图
    
    % 打开一个新的 figure
    fig = figure('Name', 'Radiation and Impurity Concentration Comparison', ...
           'NumberTitle', 'off', ...
           'Color', 'w', ...  % 白色背景
           'Units', 'inches', ...
           'Position', [1, 1, 12, 9]); % 符合学术论文的图片尺寸比例
    
    % 循环处理每个算例
    for iDir = 1:length(all_radiationData)
        if iDir > 3
            warning('Only displaying the first 3 cases.');
            break;
        end
        
        radInfo = all_radiationData{iDir};
        
        % 计算杂质浓度
        impurity_density = sum(radInfo.plasma.na(:,:,3:13), 3);  % Ne0到Ne10+的总和
        cz_ratio = impurity_density ./ radInfo.plasma.ne;
        
        % 处理无效值
        cz_ratio(~isfinite(cz_ratio) | cz_ratio <= 0) = NaN;
        
        % 对杂质浓度数据取对数（处理零值）
        log_cz_ratio = log10(max(cz_ratio, all_cz_ratio_min));
        
        % 对总辐射数据取对数（处理零值）
        log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));
        
        % 对Ne辐射数据取对数（处理零值）
        log_totrad_Ne = log10(max(radInfo.totrad_Ne, all_totrad_Ne_min));
        
        %% (1) 第1行：总辐射分布
        subplot(3, 3, iDir)
        surfplot(radInfo.gmtry, log_totrad_ns);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        
        % 统一色标（使用对数全局 min/max）
        caxis([log10(1e5), log10(1e7)]);  % 自己设置colorbar范围
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(1e7)-2);
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log10(1e5), log10(1e7), 4);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14);
        
        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        title('$p_{rad}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
        axis square; box on;
        
        % 在左上角添加case标签
        text(0.05, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
             'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
        
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
        
        %% (2) 第2行：Ne杂质辐射分布
        subplot(3, 3, iDir+3)
        surfplot(radInfo.gmtry, log_totrad_Ne);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        
        % 统一色标（使用Ne辐射的对数全局 min/max）
        % 设置Ne辐射的colorbar范围（根据实际数据范围调整）
        caxis([log10(1e5), log10(1e7)]);  % 可根据实际数据调整
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(1e7)-2);
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_Ne_ticks = linspace(log10(1e5), log10(1e7), 4);
        % 转换回原始值并除以缩放因子
        real_Ne_ticks = 10.^log_Ne_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_Ne_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_Ne_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14);
        
        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        title('$p_{rad,Ne}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
        axis square; box on;

        % 在左上角添加case标签
        text(0.05, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
         'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
        
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
        
        %% (3) 第3行：杂质浓度分布
        subplot(3, 3, iDir+6)
        surfplot(radInfo.gmtry, log_cz_ratio);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        
        % 设置统一的色标范围（使用对数值）
        caxis([log10(1e-3), log10(1e-1)]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_min = floor(log10(1e-3));
        scale_factor = 10^exp_min;
        
        % 计算对数刻度位置
        log_cz_ticks = linspace(log10(1e-3), log10(1e-1), 4);
        % 转换回原始值并除以缩放因子
        real_cz_ticks = 10.^log_cz_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_cz_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_cz_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14);
        
        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_min), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        title('$C_{Ne}$', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        axis square; box on;

        % 在左上角添加case标签
        text(0.05, 0.95, case_labels{min(iDir, length(case_labels))}, 'Units', 'normalized', ...
         'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Interpreter', 'latex');
        
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    end
    
    %% 4) 保存图形到 .fig 文件和高分辨率PNG文件
    figFilename = sprintf('RadiationAndCzDist_%s', timeSuffix);
    figFullPath = fullfile(pwd, [figFilename, '.fig']);
    savefig(figFullPath);
    
    % 同时保存为高质量的PNG格式，适合学术论文使用
    print(gcf, [figFullPath(1:end-4), '.png'], '-dpng', '-r300', '-opengl');
    
    fprintf('Comparison figure has been saved to: %s\n', figFullPath);
    fprintf('Also saved as PNG format for publication use\n');
end