function plot_ionization_source_and_poloidal_stagnation_point(all_fullfileDirs_collected, domain)
    % =========================================================================
    % 功能：
    %   针对每个目录(算例)，在 2D 平面上绘制：
    %     1) 电离源分布 (ionSource2D) -- 用已有 surfplot(gmtry, data2D)
    %     2) 极向速度停滞点 (poloidal velocity = 0 或符号转变)
    %        - 用黑色散点标记每个网格上的停滞点
    %        - 用黑色虚线将同一个 j (通量管方向) 上的停滞点按 i 递增连接起来
    %   最终在图例中说明：黑色虚线 => “u_{pol}=0 (Stagnation line)”
    %
    % 输入参数：
    %   all_fullfileDirs_collected : 包含多个算例目录的 cell 数组(来自主脚本)
    %   domain                     : 用户选择的绘图区域 (0=全域,1=上偏滤器,2=下偏滤器)
    %     （在本示例中，用于在绘图后裁剪可视范围 xlim/ylim；请根据装置真实尺寸修改）
    %
    % 依赖函数：
    %   - read_b2fgmtry.m  (读取几何信息, 生成 gmtry.crx/cry 等)
    %   - read_b2fplasmf.m (读取等离子体分布, 生成 plasma_tmp.na/ua/fna_mdf/sna 等)
    %   - surfplot.m       (已有的绘图函数, 能基于 gmtry.crx/cry 对 data2D 做 2D 彩色图)
    %   - plot3sep.m       (可选, 在图上叠加分离器/壁结构)
    %   - detect_poloidal_stagnation.m (示例在脚本下方)
    %   - computeCellCentersFromCorners.m (计算网格中心坐标, 用于散点和连线)
    %
    % 注意：
    %   - 在 SOLPS 中，gmtry.crx/cry 存储网格四角坐标(大小 ~ [nx, ny, 4])。
    %   - 本脚本示例中，ionSource2D(i,j) 和 uPol2D(i,j) 都是 [nx x ny] 的二维矩阵。
    %   - 若 domain=1 或 2，示例中仅做了简单的 xlim/ylim 裁剪(示例值)；请根据装置几何修改。
    % =========================================================================
    
        % ========== (0) 遍历所有算例目录，逐个绘图 ==========
        for iDir = 1:length(all_fullfileDirs_collected)
            currentDir  = all_fullfileDirs_collected{iDir};
            b2fplasmf_file = fullfile(currentDir,'b2fplasmf');
            gmtry_file     = fullfile(currentDir,'b2fgmtry');
    
            if ~exist(b2fplasmf_file,'file') || ~exist(gmtry_file,'file')
                fprintf('Skipping %s (missing key file)\n', currentDir);
                continue;
            end
    
            % ---------- 读取几何 & 等离子体数据 ----------
            try
                gmtry_tmp   = read_b2fgmtry(gmtry_file);
                [nx_tmp, ny_tmp] = size(gmtry_tmp.crx(:,:,1));
                [~, plasma_tmp]  = read_b2fplasmf(b2fplasmf_file, nx_tmp-2, ny_tmp-2, 13);
            catch ME
                fprintf('Error reading from %s: %s\n', currentDir, ME.message);
                continue;
            end
    
            % ---------- 计算 ionSource2D & uPol2D (大小 ~ [nx_tmp x ny_tmp]) ----------
            [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp);
    
            % ---------- 新建 figure, 绘制电离源分布 ----------
            figName = sprintf('IonSource & Stagnation: %s', currentDir);
            figure('Name', figName, 'NumberTitle','off', 'Color','w',...
                   'DefaultAxesFontSize',14, 'DefaultTextFontSize',14);
            hold on;
    
            % (1) 调用已有 surfplot 绘制电离源
            surfplot(gmtry_tmp, ionSource2D);
            shading interp; view(2);
            colormap(jet); colorbar;
    
            % 可选: 在图上叠加分离器/结构 (plot3sep)
            plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.0);
    
            % 设置标题等
            title('Ionization Source (1e13 m^-3 s^-1)','FontSize',14);
            xlabel('R (m)'); ylabel('Z (m)');
            axis equal; axis tight; box on;  
            grid on;
    
            % (2) 根据 domain 进行可视范围裁剪(示例)
            if domain~=0
                switch domain
                    case 1  % 上偏滤器区域 (示例数值)
                        xlim([1.30, 2.00]);
                        ylim([0.50, 1.20]);
                    case 2  % 下偏滤器区域
                        xlim([1.30, 2.05]);
                        ylim([-1.15, -0.40]);
                end
            end
    
            % 在图上标注目录(可选)
            uicontrol('Style','text',...
                'String', currentDir,...
                'units','normalized',...
                'Position',[0.25 0.96 0.5 0.03],...
                'BackgroundColor','w','ForegroundColor','k','FontSize',10);
    
            % ---------- (3) 寻找极向速度停滞点并叠加 (黑色散点 + 黑色虚线) ----------
            % 3.1) 先检测 uPol2D 的正负号转变 (例如 j=15..25 表示SOL?)
            stagnationMask = detect_poloidal_stagnation(uPol2D, 15, 25);
    
            % 3.2) 计算网格中心(或你也可用 gmtry.crx/cry 某种插值)
            [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);
    
            % 3.3) 在电离源分布图上先绘制散点 (黑色点)
            [iPosVec, jPosVec] = find(stagnationMask == 1);
            for kk = 1:length(iPosVec)
                ii = iPosVec(kk);
                jj = jPosVec(kk);
                rr = rCenter(ii, jj);
                zz = zCenter(ii, jj);
    
                % 如果要让散点显示在电离源表面 => Z 取 data 值(ionSource2D)
                valZ = ionSource2D(ii, jj);
                plot3(rr, zz, valZ, 'k.', 'MarkerSize', 10, 'HandleVisibility','off');
            end
    
            % 3.4) 在相同图上，用黑色虚线将同一个 j (通量管方向) 的点按 i 从小到大连起来
            %      => 这样就能看出在每条通量管上停滞点随半径从内到外的分布
            unique_jPos = unique(jPosVec);  % 取所有出现过停滞点的 j
    
            for jOne = reshape(unique_jPos,1,[])
                % 找此 jOne 下所有停滞点 iPos
                idx4thisJ = find(jPosVec == jOne);
                iList     = iPosVec(idx4thisJ);
    
                if length(iList)<2
                    % 若只有一个或没有点，则无法连线(只画散点)
                    continue;
                end
    
                % 按从内到外 => i 递增排序
                [iList_sorted, sortIndex] = sort(iList);
                % 取对应 R/Z/ionSource
                rLine = zeros(size(iList_sorted));
                zLine = zeros(size(iList_sorted));
                valLine = zeros(size(iList_sorted));
                for mm = 1:length(iList_sorted)
                    i_sorted = iList_sorted(mm);
                    rLine(mm)   = rCenter(i_sorted, jOne);
                    zLine(mm)   = zCenter(i_sorted, jOne);
                    valLine(mm) = ionSource2D(i_sorted, jOne);
                end
    
                % plot3( rLine, zLine, valLine ), 用黑色虚线
                % 并设置 DisplayName => "u_{pol}=0 line"
                % 仅让第一条线进入图例(避免重复) => handleVisibility
                if jOne == unique_jPos(1)
                    plot3(rLine, zLine, valLine, 'k--', 'LineWidth',1.2, ...
                          'DisplayName','u_{pol}=0 (Stagnation line)');
                else
                    % 之后的线不重复进 legend
                    plot3(rLine, zLine, valLine, 'k--', 'LineWidth',1.2, ...
                          'HandleVisibility','off');
                end
            end
    
            % ---------- (4) 做个简单图例 ----------
            % 由于 Ion Source 已经自动 handleVisibility='on',
            % Lines we created => first line is in legend, others 'off'
            legend('Ion Source','u_{pol}=0 (Stagnation line)','Location','best');
    
            % ---------- (5) 保存图 (可选) ----------
            saveFigureWithTimestamp('IonSource_Stagnation');
    
            hold off;
        end
    
        fprintf('\n>>> Finished: Ionization source & poloidal stagnation point distribution (with line) for all directories.\n');
    end
    
    
    %% ========== compute_ionSource_and_uPol_2D (示例) ==========
    function [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp)
    % 功能：对整张网格 (i=1..nx, j=1..ny) 计算电离源和极向速度
    %       (仅示例，实际可按自己项目定义)
    %   ionSource2D(i,j) = -(coeff0 + coeff1*n3)*1e-13
    %   uPol2D(i,j)      = GammaPol / nImp
    % (或其他类似定义)
    %
    % 假设 gmtry_tmp.bb(i,j,...) 提供磁场信息,
    %      plasma_tmp.na/fna_mdf/sna 提供粒子密度与源项
    % 也可以做 Z^2加权平行速度投影等，这里仅演示
    
        [nx, ny] = size(gmtry_tmp.crx(:,:,1));
        ionSource2D = zeros(nx, ny);
        uPol2D      = zeros(nx, ny);
    
        for jPos = 1:ny
            for iPos = 1:nx
                % =========== 1) 计算电离源 (示例) ===========
                sVal = 0;
                if isfield(plasma_tmp, 'sna') && ndims(plasma_tmp.sna)>=4
                    if size(plasma_tmp.sna,3)>=2 && size(plasma_tmp.sna,4)>=3
                        coeff0 = plasma_tmp.sna(iPos, jPos, 1, 3);
                        coeff1 = plasma_tmp.sna(iPos, jPos, 2, 3);
                        if size(plasma_tmp.na,3)>=3
                            n3 = plasma_tmp.na(iPos, jPos, 3);
                        else
                            n3 = 0;
                        end
                        sVal = -(coeff0 + coeff1*n3)*1e-13;
                    end
                end
                ionSource2D(iPos, jPos) = sVal;
    
                % =========== 2) 计算极向速度 (示例) ===========
                gammaPol = 0;
                nImp     = 0;
                for sp = 4:13
                    if isfield(plasma_tmp,'fna_mdf')
                        gammaPol = gammaPol + plasma_tmp.fna_mdf(iPos, jPos, 1, sp);
                    end
                    if sp <= size(plasma_tmp.na,3)
                        nImp = nImp + plasma_tmp.na(iPos, jPos, sp);
                    end
                end
                if nImp>0
                    uPol2D(iPos,jPos) = gammaPol / nImp;
                else
                    uPol2D(iPos,jPos) = 0;
                end
            end
        end
    end
    
    
    %% ========== detect_poloidal_stagnation (示例) ==========
    function stagnationMask = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax)
    % 功能：寻找 (iPos,jPos) 与 (iPos+1,jPos) 之间极向速度符号相反 => 停滞点
    %       仅在 j=[jSOLmin..jSOLmax] 范围内搜索 (示例：外SOL~15..25)
    %
    % 返回 stagnationMask(i,j)=1 表示此网格"附近"存在 u_pol=0
    %
        [nx, ny] = size(uPol2D);
        stagnationMask = zeros(nx, ny);
    
        jLo = max(jSOLmin, 1);
        jHi = min(jSOLmax, ny);
    
        for jPos = jLo : jHi
            for iPos = 1 : (nx-1)
                if uPol2D(iPos, jPos)* uPol2D(iPos+1, jPos) < 0
                    stagnationMask(iPos, jPos) = 1;
                end
            end
        end
    end
    
    
    %% ========== computeCellCentersFromCorners (示例) ==========
    function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 功能：将 4个角坐标 做平均 => 作为 网格(i,j)的中心坐标
    %   crx(i,j,1..4), cry(i,j,1..4) => 对应 (i,j)网格的 4角
        [nx, ny, ~] = size(crx);
        rCenter = zeros(nx, ny);
        zCenter = zeros(nx, ny);
        for i = 1:nx
            for j = 1:ny
                rCenter(i,j) = 0.25 * (crx(i,j,1)+crx(i,j,2)+crx(i,j,3)+crx(i,j,4));
                zCenter(i,j) = 0.25 * (cry(i,j,1)+cry(i,j,2)+cry(i,j,3)+cry(i,j,4));
            end
        end
    end
    
    
    %% ========== saveFigureWithTimestamp ==========
    function saveFigureWithTimestamp(baseName)
    % 功能：将当前图形保存为 <baseName>_<YYYYMMDD_HHMMSS>.fig，避免覆盖
        set(gcf,'Units','pixels','Position',[100 50 1200 800]);
        set(gcf,'PaperPositionMode','auto');
    
        timestampStr = datestr(now,'yyyymmdd_HHMMSS');
        outFile = sprintf('%s_%s.fig', baseName, timestampStr);
        savefig(outFile);
        fprintf('Figure saved: %s\n', outFile);
    end