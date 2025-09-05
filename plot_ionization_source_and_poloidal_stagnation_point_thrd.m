function plot_ionization_source_and_poloidal_stagnation_point_thrd(all_radiationData, domain)
    % =========================================================================
    % 功能：
    %   针对每个算例(已在 all_radiationData 中存有 gmtry/plasma 等信息)，在 2D 平面上绘制：
    %     1) 电离源分布 (ionSource2D)
    %     2) 极向速度停滞点 (u_pol = 0 或符号变换)
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
    %   - compute_ionSource_and_uPol_2D (本脚本中附带)
    %   - detect_poloidal_stagnation    (本脚本中附带)
    %   - computeCellCentersFromCorners (本脚本中附带)
    %   - saveFigureWithTimestamp       (本脚本中附带)
    %
    % 注意：
    %   - 原脚本中会对 b2fplasmf_file / gmtry_file 做 I/O 读取；
    %     现在已改为直接使用 all_radiationData{iDir}.gmtry 和 .plasma。
    %   - domain=1 或 2 时，会对绘图的 xlim / ylim 做简单示例性裁剪，实际应用请根据装置尺寸修改。
    %   - 极向速度停滞点用 plot3(rr,zz,valZ,'k.') 叠加在电离源分布图上。
    % =========================================================================
    
        % ========== (0) 遍历所有算例并绘图 ==========
        totalDirs = length(all_radiationData);
        for iDir = 1 : totalDirs
            
            % ------------------- 1) 获取数据 -------------------
            dataStruct   = all_radiationData{iDir};
            gmtry_tmp    = dataStruct.gmtry;   % 几何信息 (已在主脚本中读取并存入)
            plasma_tmp   = dataStruct.plasma;  % 等离子体信息 (同上)
            currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注
            
            % ------------------- 2) 计算 ionSource2D / uPol2D -------------------
            [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp);
    
            % ------------------- 3) 新建 figure, 绘制电离源分布 -------------------
            figName = sprintf('IonSource & Stagnation: %s', currentLabel);
            figure('Name', figName, 'NumberTitle','off', 'Color','w',...
                   'DefaultAxesFontSize',14, 'DefaultTextFontSize',14);
            hold on;
            
            % (3.1) 调用 surfplot 绘制电离源彩色图
            surfplot(gmtry_tmp, ionSource2D);
            shading interp; 
            view(2);
            colormap(jet); 
            colorbar;
            
            % (3.2) 可选地在图上叠加分离器/结构
            plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.0);
            
            % (3.3) 设置标题、坐标轴等
            title('Ionization Source (1e13 m^{-3} s^{-1})','FontSize',14);
            xlabel('R (m)'); 
            ylabel('Z (m)');
            axis equal; 
            axis tight; 
            box on;  
            grid on;
    
            % ------------------- 4) 根据 domain 裁剪绘制区域 (示例) -------------------
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
            
            % (4.1) 在图窗上标注目录/算例名 (可选)
            uicontrol('Style','text',...
                      'String', currentLabel,...
                      'Units','normalized',...
                      'Position',[0.25 0.96 0.5 0.03],...
                      'BackgroundColor','w','ForegroundColor','k','FontSize',10);
    
            % ------------------- 5) 检测并标注极向速度停滞点 -------------------
            % 这里示例检测 j=15..25 范围(外SOL区域), 具体范围可按需求修改
            jSOLmin = 15; 
            jSOLmax = 25;
            i_outer = 25; % 外偏滤器入口i位置
            i_inner = 74; % 内偏滤器入口i位置
            stagnationMask = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, i_outer, i_inner);
    
            % (5.1) 计算网格中心，用于散点叠加
            [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);
            
            % (5.2) 找到停滞点所在 (i,j)，并在电离源图上叠加散点
            [iPosVec, jPosVec] = find(stagnationMask == 1);
            for k = 1 : length(iPosVec)
                ii = iPosVec(k);
                jj = jPosVec(k);
                rr = rCenter(ii, jj);
                zz = zCenter(ii, jj);
    
                % 为了让散点浮在彩色表面上 => Z 取 ionSource2D 的数值(也可固定)
                valZ = ionSource2D(ii, jj);
                plot3(rr, zz, valZ, 'k.', 'MarkerSize', 10);
            end
            
            % (5.3) 做个简单图例
            legend('Ion Source','u_{pol}=0','Location','best');
            
            % ------------------- 6) 保存图(带时间戳) -------------------
            saveFigureWithTimestamp('IonSource_Stagnation');

            % ------------------- 7) 保存 ionSource2D 数组到文件 -------------------
            timestampStr = datestr(now,'yyyymmdd_HHMMSS');
            dataFileName = sprintf('IonSource2Dthrd_%s.dat', timestampStr);
            dlmwrite(dataFileName, ionSource2D, 'delimiter', '\t'); % 使用 tab 分隔符，可根据需要修改
            fprintf('IonSource2D data saved to: %s\n', dataFileName);

            hold off;
        end
    
        fprintf('\n>>> Finished: Ionization source & poloidal stagnation point distribution for all directories.\n');
    
    end % END of main function
    
    
    %% =========================================================================
    %% (A) compute_ionSource_and_uPol_2D
    %%    功能：对整张网格 (i=1..nx, j=1..ny) 计算电离源和极向速度
    %% =========================================================================
    function [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp)
    % 功能：
    %   - ionSource2D(i,j) = -(coeff0 + coeff1*n3)*1e-13  (示例做法)
    %   - uPol2D(i,j)      = GammaPol / (ImpDensity)      (示例做法)
    %   你可根据实际 SOLPS 数据结构进行调整，比如杂质是否存在等。
    %
    % 输入：
    %   plasma_tmp : 存有 na, fna_mdf, sna 等字段的结构
    %   gmtry_tmp  : 存有 crx, cry, bb, hx 等字段的结构
    %
    % 输出：
    %   ionSource2D, uPol2D : 大小 ~ [nx, ny]
    
        [nx, ny, ~] = size(gmtry_tmp.crx);  % crx(i,j,4角)
    
        ionSource2D = zeros(nx, ny);
        uPol2D      = zeros(nx, ny);
    
        for jPos = 1 : ny
            for iPos = 1 : nx
    
                % ========== 1) 计算电离源 (示例) ==========
                sVal = (plasma_tmp.sna(iPos, jPos, 4));
                ionSource2D(iPos, jPos) = sVal;
    
                % ========== 2) 计算极向速度 (示例) ==========
                gammaPol = 0;
                nImp     = 0;  % 杂质粒子总数
                for sp = 4 : 13
                    % gammaPol => plasma_tmp.fna_mdf(iPos,jPos,1,sp)
                    if isfield(plasma_tmp,'fna_mdf')
                        gammaPol = gammaPol + plasma_tmp.fna_mdf(iPos, jPos, 1, sp);
                    end
                    % 累加杂质密度 => na(iPos,jPos,sp)
                    if sp <= size(plasma_tmp.na, 3)
                        nImp = nImp + plasma_tmp.na(iPos, jPos, sp);
                    end
                end
    
                if nImp > 0
                    uPol2D(iPos,jPos) = gammaPol / nImp;
                else
                    uPol2D(iPos,jPos) = 0;
                end
    
            end
        end
    end
    
    
    %% =========================================================================
    %% (B) detect_poloidal_stagnation（修改版）
    %%    功能：在每个通量管中分别检测靠近内外偏滤器入口的停滞点
    %% =========================================================================
    function stagnationMask = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, i_outer, i_inner)
    % 功能：
    %   - 在指定的 j 范围 [jSOLmin..jSOLmax]，若 uPol2D(i,j) 与 uPol2D(i+1,j) 的乘积<0，
    %     则认为 (i,j) 是一处速度符号变换点 => 停滞点。
    %
    % 注意：只是一个简单示例，有时还需考虑速度近似为零的阈值，而非仅符号转变。
    %
    % 输出：
    %   stagnationMask(i,j) = 1 => 停滞点, 0 => 否
    
        [nx, ny] = size(uPol2D);
        stagnationMask = zeros(nx, ny);
    
        jLo = max(jSOLmin, 1);
        jHi = min(jSOLmax, ny);

        % 计算分界点（取内外入口中点）
        mid_i = 50; % 取中间值
    
        for jPos = jLo : jHi
            stag_i_list = [];
            % 1. 检测所有符号变化的i位置
            for iPos = 1 : (nx - 1)
                if uPol2D(iPos, jPos) * uPol2D(iPos+1, jPos) < 0
                    stag_i_list = [stag_i_list, iPos];
                end
            end
            
            % 2. 将候选点分为内外两组
            outer_candidates = stag_i_list(stag_i_list <= mid_i); % 外区域候选
            inner_candidates = stag_i_list(stag_i_list > mid_i);  % 内区域候选
            
            % 3. 处理外区域候选点（选择最接近i_outer的点）
            if ~isempty(outer_candidates)
                [~, idx] = min(abs(outer_candidates - i_outer));
                outer_stag_i = outer_candidates(idx);
                stagnationMask(outer_stag_i, jPos) = 1;
            end
            
            % 4. 处理内区域候选点（选择最接近i_inner的点）
            if ~isempty(inner_candidates)
                [~, idx] = min(abs(inner_candidates - i_inner));
                inner_stag_i = inner_candidates(idx);
                stagnationMask(inner_stag_i, jPos) = 1;
            end
        end
    end
    
    
    %% =========================================================================
    %% (C) computeCellCentersFromCorners
    %%     功能：将网格四角坐标做平均，得到网格中心
    %% =========================================================================
    function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 输入：
    %   crx(i,j,1..4), cry(i,j,1..4) => 第 (i,j) 网格 4个角的 (R,Z) 坐标
    %
    % 输出：
    %   rCenter(i,j), zCenter(i,j)   => (i,j) 网格中心的 (R,Z)
    
        [nx, ny, ~] = size(crx);
        rCenter = zeros(nx, ny);
        zCenter = zeros(nx, ny);
    
        for i = 1 : nx
            for j = 1 : ny
                rCenter(i,j) = 0.25 * ( crx(i,j,1) + crx(i,j,2) + crx(i,j,3) + crx(i,j,4) );
                zCenter(i,j) = 0.25 * ( cry(i,j,1) + cry(i,j,2) + cry(i,j,3) + cry(i,j,4) );
            end
        end
    end
    
    
    %% =========================================================================
    %% (D) saveFigureWithTimestamp
    %%     功能：保存当前 figure => <baseName>_<YYYYMMDD_HHMMSS>.fig
    %% =========================================================================
    function saveFigureWithTimestamp(baseName)
        % 设置较大窗口，以免保存时被裁剪
        set(gcf,'Units','pixels','Position',[100 50 1200 800]);
        set(gcf,'PaperPositionMode','auto');
    
        % 生成时间戳，并构造输出文件名
        timestampStr = datestr(now,'yyyymmdd_HHMMSS');
        outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    
        savefig(outFile);
        fprintf('Figure saved: %s\n', outFile);
    end