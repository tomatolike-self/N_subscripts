function plot_radiation_Nz_distribution(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制算例的辐射分布和杂质离子浓度分布对比图。
    %       第1行显示总辐射分布，第2行显示N杂质辐射分布，第3行显示杂质离子浓度分布。
    %       每组算例在子图左上角添加标识。
    %       同时把各算例的辐射信息输出到一个带时间后缀的 .txt 文件中。
    %       绘图后会自动保存 .fig 文件，文件名包含时间后缀，避免互相覆盖。
    %       对辐射分布使用对数颜色标尺，但标尺显示的是真实值而非对数值。
    %
    %       注意：杂质离子浓度定义为 (N1+ + N2+ + ... + N7+) / ne，不包含中性N原子。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例辐射信息的 cell 数组 (支持1-2个算例)
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室或偏滤器结构信息)
    %       .totrad_ns       (matrix) - 总辐射分布
    %       .totrad_N        (matrix) - N杂质辐射分布
    %       .plasma.na       (matrix) - 杂质离子密度数据，na(:,:,4:10)为N1+到N7+
    %       .neut.dab        (matrix) - 中性原子密度数据，dab(:,:,3)为N0（杂质离子浓度计算中不使用）
    %       .plasma.ne       (matrix) - 电子密度数据
    %   3) MATLAB 版本需要支持 savefig 等功能。
    % =========================================================================
    
    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', 16);
    set(0, 'DefaultLineLineWidth', 1.5);
    
    % 检查输入数据数量并设置相应的标签
    num_cases = length(all_radiationData);
    if num_cases < 1 || num_cases > 2
        error('This function expects 1 to 2 cases, but received %d.', num_cases);
    end

    % 根据算例数量分配标签，只支持fav和unfav两组
    predefined_labels = {'fav. $B_T$', 'unfav. $B_T$'};
    case_labels = predefined_labels(1:num_cases);  % 取前num_cases个标签
    subplot_cols = num_cases;  % 列数等于算例数量
    
    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围
    all_totrad_ns_min = +Inf;   all_totrad_ns_max = -Inf;
    all_totrad_N_min = +Inf;    all_totrad_N_max = -Inf;
    all_cz_ratio_min = +Inf;    all_cz_ratio_max = -Inf;
    
    % 遍历每个算例，更新全局 min/max
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % Total radiation (no-separatrix)
        all_totrad_ns_min = min(all_totrad_ns_min, min(radInfo.totrad_ns(radInfo.totrad_ns>0)));
        all_totrad_ns_max = max(all_totrad_ns_max, max(radInfo.totrad_ns(:)));
        
        % N radiation (no-separatrix)
        all_totrad_N_min = min(all_totrad_N_min, min(radInfo.totrad_N(radInfo.totrad_N>0)));
        all_totrad_N_max = max(all_totrad_N_max, max(radInfo.totrad_N(:)));
        
        % 计算杂质离子浓度（N1+-N7+离子态密度 / 电子密度）
        % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
        % N1+ 到 N7+ 的离子态密度
        impurity_ion_density = sum(radInfo.plasma.na(:,:,4:10), 3);  % N1+到N7+的总和

        cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;  % 杂质离子浓度
        
        % 找出有效的杂质浓度值（避免除以零或非物理值）
        valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
        if ~isempty(valid_cz)
            all_cz_ratio_min = min(all_cz_ratio_min, min(valid_cz));
            all_cz_ratio_max = max(all_cz_ratio_max, max(valid_cz(:)));
        end
    end
    
    % 防止最小值太小导致对数标尺的问题
    all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max*1e-6);
    all_totrad_N_min = max(all_totrad_N_min, all_totrad_N_max*1e-6);
    
    
    %% 2) 把辐射信息输出到带时间后缀的文件中
    % 生成一个时间戳
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');
    
    % 拼接输出的 txt 文件名
    radInfoFilename = fullfile(pwd, ['radiation_ion_concentration_info_N_', timeSuffix, '.txt']);
    
    % 打开文件写入（若失败，则仅在屏幕打印）
    fid = fopen(radInfoFilename, 'w');
    if fid < 0
        warning('Cannot open file %s for writing. Will just print to screen.', radInfoFilename);
    end
    
    % 逐个算例打印/写入必要信息
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % 计算杂质离子浓度平均值和最大值
        % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
        % N1+ 到 N7+ 的离子态密度
        impurity_ion_density = sum(radInfo.plasma.na(:,:,4:10), 3);  % N1+到N7+的总和

        cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;
        valid_cz = cz_ratio(isfinite(cz_ratio) & cz_ratio > 0);
        avg_cz = mean(valid_cz);
        max_cz = max(valid_cz(:));
        
        % 计算N在内外偏滤器区域的辐射量
        % 注意：radInfo.totrad_N是N杂质辐射功率密度 (W/m³)，需要乘以体积得到总功率
        N_totrad = sum(sum(radInfo.totrad_N.*radInfo.volcell))*1e-6; % N总辐射功率 (MW)
        
        % 获取偏滤器区域索引
        index_div = [];
        outer_div_indices = [];
        inner_div_indices = [];
        
        if isfield(radInfo, 'gmtry') && isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut')
            [nxd, ~] = size(radInfo.gmtry.crx(:,:,1)); % 获取网格尺寸

            % 偏滤器区域索引: 1-24是外偏滤器区域，73-96是内偏滤器区域（对应96*26的网格）
            % gmtry.leftcut=24，gmtry.rightcut=72
            outer_div_indices = 1:radInfo.gmtry.leftcut;
            inner_div_indices = (radInfo.gmtry.rightcut+1):(nxd-2);
            index_div = [outer_div_indices, inner_div_indices];
        else
            fprintf('Warning: gmtry field or required subfields not found for case %d, skipping divertor region calculations.\n', iDir);
        end
        
        % 计算N在内外偏滤器区域的辐射量
        N_outer_div_rad = 0;
        N_inner_div_rad = 0;
        
        if ~isempty(outer_div_indices)
            N_outer_div_rad = sum(sum(radInfo.totrad_N(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)))*1e-6;
        end
        
        if ~isempty(inner_div_indices)
            N_inner_div_rad = sum(sum(radInfo.totrad_N(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)))*1e-6;
        end
        
        % 计算N辐射在外偏滤器、内偏滤器和总量中的占比
        N_outer_div_fraction = N_outer_div_rad / N_totrad;
        N_inner_div_fraction = N_inner_div_rad / N_totrad;
        N_div_fraction = (N_outer_div_rad + N_inner_div_rad) / N_totrad;
        
        % 计算N杂质离子在整个计算区域的总数量（密度×体积）
        % 注意：为了与杂质离子浓度定义保持一致，这里只统计离子态 (N1+到N7+)
        N_total_amount = 0;

        % N1+ 到 N7+ 的离子态数量
        for i_Z = 4:10 % N1+到N7+的索引为4到10
            % 确保使用裁剪后的数据 - na需要裁剪以匹配volcell维度
            na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格，与volcell匹配
            N_total_amount = N_total_amount + sum(sum(na_sliced.*radInfo.volcell));
        end

        % 注意：不包含N0中性原子，以保持与杂质离子浓度定义的一致性
        
        % 计算N杂质在偏滤器区域的数量
        N_div_amount = 0;
        N_outer_div_amount = 0;
        N_inner_div_amount = 0;
        
        if ~isempty(outer_div_indices)
            % N1+ 到 N7+ 的离子态数量
            for i_Z = 4:10
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                N_outer_div_amount = N_outer_div_amount + sum(sum(na_sliced(outer_div_indices,:).*radInfo.volcell(outer_div_indices,:)));
            end
            % 注意：不包含N0中性原子，以保持与杂质离子浓度定义的一致性
        end

        if ~isempty(inner_div_indices)
            % N1+ 到 N7+ 的离子态数量
            for i_Z = 4:10
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                N_inner_div_amount = N_inner_div_amount + sum(sum(na_sliced(inner_div_indices,:).*radInfo.volcell(inner_div_indices,:)));
            end
            % 注意：不包含N0中性原子，以保持与杂质离子浓度定义的一致性
        end
        
        N_div_amount = N_outer_div_amount + N_inner_div_amount;
        
        % 计算N杂质在偏滤器区域的占比（避免除零错误）
        if N_total_amount > 0
            N_div_amount_fraction = N_div_amount / N_total_amount;
            N_outer_div_amount_fraction = N_outer_div_amount / N_total_amount;
            N_inner_div_amount_fraction = N_inner_div_amount / N_total_amount;
        else
            N_div_amount_fraction = 0;
            N_outer_div_amount_fraction = 0;
            N_inner_div_amount_fraction = 0;
        end
        
        % ------ 新增：定义主SOL层和芯部边缘区域索引 ------
        main_SOL_indices = [];
        core_edge_indices = [];
        
        if isfield(radInfo, 'gmtry') && isfield(radInfo.gmtry, 'leftcut') && isfield(radInfo.gmtry, 'rightcut') && isfield(radInfo.gmtry, 'topcut')
            % 获取分离面内侧网格编号（使用topcut，96*26的网格，topcut=12）
            j_sep = radInfo.gmtry.topcut; % gmtry.topcut=12

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
        
        % ------ 新增：计算主SOL层的N粒子数和辐射量 ------
        N_main_SOL_amount = 0;
        N_main_SOL_rad = 0;
        
        if ~isempty(main_SOL_indices)
            % 计算主SOL层的N离子粒子数
            % N1+ 到 N7+ 的离子态数量
            for i_Z = 4:10
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                for i = 1:size(main_SOL_indices, 1)
                    ix = main_SOL_indices(i, 1);
                    jy = main_SOL_indices(i, 2);
                    if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                        N_main_SOL_amount = N_main_SOL_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                    end
                end
            end

            % 注意：不包含N0中性原子，以保持与杂质离子浓度定义的一致性
            
            % 计算主SOL层的N辐射量
            for i = 1:size(main_SOL_indices, 1)
                ix = main_SOL_indices(i, 1);
                jy = main_SOL_indices(i, 2);
                if ix <= size(radInfo.totrad_N, 1) && jy <= size(radInfo.totrad_N, 2)
                    N_main_SOL_rad = N_main_SOL_rad + radInfo.totrad_N(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
            N_main_SOL_rad = N_main_SOL_rad * 1e-6;  % 转换为MW
        end
        
        % 计算主SOL层的N粒子数和辐射量占比（避免除零错误）
        if N_total_amount > 0
            N_main_SOL_amount_fraction = N_main_SOL_amount / N_total_amount;
        else
            N_main_SOL_amount_fraction = 0;
        end

        if N_totrad > 0
            N_main_SOL_rad_fraction = N_main_SOL_rad / N_totrad;
        else
            N_main_SOL_rad_fraction = 0;
        end

        % ------ 新增：计算芯部边缘区域的N粒子数和辐射量 ------
        N_core_edge_amount = 0;
        N_core_edge_rad = 0;

        if ~isempty(core_edge_indices)
            % 计算芯部边缘区域的N离子粒子数
            % N1+ 到 N7+ 的离子态粒子数
            for i_Z = 4:10
                na_sliced = radInfo.plasma.na(2:end-1, 2:end-1, i_Z);  % 排除边界网格
                for i = 1:size(core_edge_indices, 1)
                    ix = core_edge_indices(i, 1);
                    jy = core_edge_indices(i, 2);
                    if ix <= size(na_sliced, 1) && jy <= size(na_sliced, 2)
                        N_core_edge_amount = N_core_edge_amount + na_sliced(ix, jy) * radInfo.volcell(ix, jy);
                    end
                end
            end

            % 注意：不包含N0中性原子，以保持与杂质离子浓度定义的一致性


            % 计算芯部边缘区域的N辐射量
            for i = 1:size(core_edge_indices, 1)
                ix = core_edge_indices(i, 1);
                jy = core_edge_indices(i, 2);
                if ix <= size(radInfo.totrad_N, 1) && jy <= size(radInfo.totrad_N, 2)
                    N_core_edge_rad = N_core_edge_rad + radInfo.totrad_N(ix, jy) * radInfo.volcell(ix, jy);
                end
            end
            N_core_edge_rad = N_core_edge_rad * 1e-6;  % 转换为MW
        else
            fprintf('Warning: gmtry field or required subfields not found for case %d, skipping SOL and core-edge calculations.\n', iDir);
            % 设置默认值
            N_main_SOL_amount = 0;
            N_main_SOL_rad = 0;
            N_core_edge_amount = 0;
            N_core_edge_rad = 0;
        end

        % 计算芯部边缘区域的N粒子数和辐射量占比（避免除零错误）
        if N_total_amount > 0
            N_core_edge_amount_fraction = N_core_edge_amount / N_total_amount;
        else
            N_core_edge_amount_fraction = 0;
        end

        if N_totrad > 0
            N_core_edge_rad_fraction = N_core_edge_rad / N_totrad;
        else
            N_core_edge_rad_fraction = 0;
        end

        % 屏幕打印
        fprintf('\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
        fprintf('\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
        fprintf('\tN radiation power:       %2.3f MW\n', N_totrad);
        fprintf('\tN outer divertor radiation: %2.3f MW (%2.1f%%)\n', N_outer_div_rad, N_outer_div_fraction*100);
        fprintf('\tN inner divertor radiation: %2.3f MW (%2.1f%%)\n', N_inner_div_rad, N_inner_div_fraction*100);
        fprintf('\tN total divertor radiation: %2.3f MW (%2.1f%%)\n', N_outer_div_rad + N_inner_div_rad, N_div_fraction*100);
        fprintf('\tN main SOL radiation: %2.3f MW (%2.1f%%)\n', N_main_SOL_rad, N_main_SOL_rad_fraction*100);
        fprintf('\tN core edge radiation: %2.3f MW (%2.1f%%)\n', N_core_edge_rad, N_core_edge_rad_fraction*100);
        fprintf('\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
        fprintf('\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
        fprintf('\tN ion total amount: %2.3e particles\n', N_total_amount);
        fprintf('\tN ions in outer divertor: %2.3e particles (%2.1f%%)\n', N_outer_div_amount, N_outer_div_amount_fraction*100);
        fprintf('\tN ions in inner divertor: %2.3e particles (%2.1f%%)\n', N_inner_div_amount, N_inner_div_amount_fraction*100);
        fprintf('\tN ions in total divertor: %2.3e particles (%2.1f%%)\n', N_div_amount, N_div_amount_fraction*100);
        fprintf('\tN ions in main SOL: %2.3e particles (%2.1f%%)\n', N_main_SOL_amount, N_main_SOL_amount_fraction*100);
        fprintf('\tN ions in core edge: %2.3e particles (%2.1f%%)\n', N_core_edge_amount, N_core_edge_amount_fraction*100);
        fprintf('\tAverage impurity ion concentration: %2.3e\n', avg_cz);
        fprintf('\tMaximum impurity ion concentration: %2.3e\n', max_cz);

        % 写入到文件
        if fid >= 0
            fprintf(fid, '\nCase %d (%s): %s\n', iDir, case_labels{min(iDir, length(case_labels))}, radInfo.dirName);
            fprintf(fid, '\tTotal radiation power:   %2.3f MW\n', radInfo.totrad);
            fprintf(fid, '\tN radiation power:       %2.3f MW\n', N_totrad);
            fprintf(fid, '\tN outer divertor radiation: %2.3f MW (%2.1f%%)\n', N_outer_div_rad, N_outer_div_fraction*100);
            fprintf(fid, '\tN inner divertor radiation: %2.3f MW (%2.1f%%)\n', N_inner_div_rad, N_inner_div_fraction*100);
            fprintf(fid, '\tN total divertor radiation: %2.3f MW (%2.1f%%)\n', N_outer_div_rad + N_inner_div_rad, N_div_fraction*100);
            fprintf(fid, '\tN main SOL radiation: %2.3f MW (%2.1f%%)\n', N_main_SOL_rad, N_main_SOL_rad_fraction*100);
            fprintf(fid, '\tN core edge radiation: %2.3f MW (%2.1f%%)\n', N_core_edge_rad, N_core_edge_rad_fraction*100);
            fprintf(fid, '\tDivertor radiation power: %2.3f MW\n', radInfo.totrad_div);
            fprintf(fid, '\tDivertor radiation fraction: %2.3f\n', radInfo.div_fraction);
            fprintf(fid, '\tN ion total amount: %2.3e particles\n', N_total_amount);
            fprintf(fid, '\tN ions in outer divertor: %2.3e particles (%2.1f%%)\n', N_outer_div_amount, N_outer_div_amount_fraction*100);
            fprintf(fid, '\tN ions in inner divertor: %2.3e particles (%2.1f%%)\n', N_inner_div_amount, N_inner_div_amount_fraction*100);
            fprintf(fid, '\tN ions in total divertor: %2.3e particles (%2.1f%%)\n', N_div_amount, N_div_amount_fraction*100);
            fprintf(fid, '\tN ions in main SOL: %2.3e particles (%2.1f%%)\n', N_main_SOL_amount, N_main_SOL_amount_fraction*100);
            fprintf(fid, '\tN ions in core edge: %2.3e particles (%2.1f%%)\n', N_core_edge_amount, N_core_edge_amount_fraction*100);
            fprintf(fid, '\tAverage impurity ion concentration: %2.3e\n', avg_cz);
            fprintf(fid, '\tMaximum impurity ion concentration: %2.3e\n', max_cz);
        end
    end

    % 如果文件成功打开，则 fclose 并提示
    if fid >= 0
        fclose(fid);
        fprintf('\nRadiation and impurity ion concentration info has been written to: %s\n', radInfoFilename);
    end


    %% 3) 创建动态子图布局，绘制所有算例的对比图

    % 根据算例数量调整图片尺寸
    if num_cases == 1
        fig_width = 6;   % 1列时增大图片宽度
        fig_height = 12; % 增大图片高度
    else
        fig_width = 12;  % 2列时增大图片宽度
        fig_height = 12; % 增大图片高度
    end

    % 打开一个新的 figure
    fig = figure('Name', 'Radiation and Impurity Ion Concentration Comparison', ...
           'NumberTitle', 'off', ...
           'Color', 'w', ...  % 白色背景
           'Units', 'inches', ...
           'Position', [1, 1, fig_width, fig_height]); % 增大图窗尺寸以便更好展示

    % 循环处理每个算例
    for iDir = 1:num_cases

        radInfo = all_radiationData{iDir};

        % 计算杂质离子浓度
        % 注意：杂质离子浓度不包含中性粒子，只计算离子态贡献
        % N1+ 到 N7+ 的离子态密度
        impurity_ion_density = sum(radInfo.plasma.na(:,:,4:10), 3);  % N1+到N7+的总和

        cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;

        % 处理无效值
        cz_ratio(~isfinite(cz_ratio) | cz_ratio <= 0) = NaN;

        % 对杂质浓度数据取对数（处理零值）
        log_cz_ratio = log10(max(cz_ratio, all_cz_ratio_min));

        % 对总辐射数据取对数（处理零值）
        log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));

        % 对N辐射数据取对数（处理零值）
        log_totrad_N = log10(max(radInfo.totrad_N, all_totrad_N_min));

        %% (1) 第1行：总辐射分布
        subplot(3, subplot_cols, iDir)
        surfplot(radInfo.gmtry, log_totrad_ns);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);

        % 统一色标（使用对数全局 min/max）
        caxis([log10(1e5), log10(200e5)]);  % 自己设置colorbar范围

        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;

        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(200e5)-2);
        scale_factor = 10^exp_max;

        % 计算对数刻度位置
        log_ticks = linspace(log10(1e5), log10(200e5), 4);
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
        title('$P_{rad}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
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

        %% (2) 第2行：N杂质辐射分布
        subplot(3, subplot_cols, iDir+subplot_cols)
        surfplot(radInfo.gmtry, log_totrad_N);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);

        % 统一色标（使用N辐射的对数全局 min/max）
        % 设置N辐射的colorbar范围（根据实际数据范围调整）
        caxis([log10(1e5), log10(200e5)]);  % 可根据实际数据调整

        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;

        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(200e5)-2);
        scale_factor = 10^exp_max;

        % 计算对数刻度位置
        log_N_ticks = linspace(log10(1e5), log10(200e5), 4);
        % 转换回原始值并除以缩放因子
        real_N_ticks = 10.^log_N_ticks / scale_factor;

        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_N_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_N_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14);

        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'FontName', 'Times New Roman', 'FontSize', 14, 'Interpreter', 'latex');

        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
        title('$P_{rad,N}$ (W/m$^3$)', 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
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
        subplot(3, subplot_cols, iDir+2*subplot_cols)
        surfplot(radInfo.gmtry, log_cz_ratio);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);

        % 设置统一的色标范围（使用对数值）
        caxis([log10(1e-3), log10(200e-3)]);

        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;

        % 计算共同的指数基数，简化显示
        exp_min = floor(log10(1e-3));
        scale_factor = 10^exp_min;

        % 计算对数刻度位置
        log_cz_ticks = linspace(log10(1e-3), log10(200e-3), 4);
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
        title('$C_{N}$', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'latex');
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

    %% 4) 保存图形到 .fig 文件
    figFilename = sprintf('RadiationAndIonConcentration_N_%dcases_%s', num_cases, timeSuffix);
    figFullPath = fullfile(pwd, [figFilename, '.fig']);
    savefig(figFullPath);

    fprintf('Comparison figure has been saved to: %s\n', figFullPath);
end
