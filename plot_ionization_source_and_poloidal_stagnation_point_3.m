function plot_ionization_source_and_poloidal_stagnation_point_3(all_radiationData, domain)
    % =========================================================================
    % 功能：在2D平面上绘制电离源分布和极向速度停滞点
    % 输入：
    %   all_radiationData : 包含各算例数据的cell数组，每个元素需包含：
    %       .dirName : 算例名称
    %       .gmtry   : 几何结构（含crx,cry等字段）
    %       .plasma  : 等离子体数据（含na,fna_mdf,sna等字段）
    %   domain       : 绘图区域选择（0=全区域，1=EAST上偏滤器，2=EAST下偏滤器）
    % 更新说明：
    %   1. 修正极向速度计算中的条件判断语法
    %   2. 增强数组维度检查防止索引越界
    %   3. 优化计算逻辑提升执行效率
    % =========================================================================

    %% 全局参数设置
    fontSize = 14;           % 统一字体大小
    markerSize = 12;         % 停滞点标记尺寸
    stagnationColor = 'k';   % 停滞点颜色
    ionSourceScale = 1e13;   % 电离源单位换算系数

    %% 遍历所有算例
    for iDir = 1:length(all_radiationData)
        %% 数据提取与校验
        dataStruct = all_radiationData{iDir};
        try
            gmtry_tmp = dataStruct.gmtry;
            plasma_tmp = dataStruct.plasma;
            currentLabel = dataStruct.dirName;
        catch
            error('无效数据结构: 第%d个算例缺少必要字段', iDir);
        end

        %% 计算关键物理量
        [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp, ionSourceScale);
        [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);
        
        %% 停滞点检测
        jSOLrange = [15, 25]; % 外SOL径向索引范围
        stagnationMask = detect_poloidal_stagnation(uPol2D, jSOLrange);

        %% 绘图设置
        fig = figure('Name',['IonSource_Stagnation: ',currentLabel],...
            'NumberTitle','off','Color','w','Position',[100 100 800 600]);
        ax = axes(fig);
        hold(ax, 'on');
        
        %% 绘制电离源分布
        surfplot(gmtry_tmp, ionSource2D);
        shading interp;
        colormap(jet);
        cbar = colorbar;
        cbar.Label.String = 'Ionization Source (1e13 m^{-3} s^{-1})';
        cbar.Label.FontSize = fontSize;
        
        %% 叠加分离器结构
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.2);

        %% 标注停滞点
        [iIdx, jIdx] = find(stagnationMask);
        plot3(rCenter(stagnationMask), zCenter(stagnationMask),...
            ionSource2D(stagnationMask)*1.1, 'o',... % 抬升高度避免被表面覆盖
            'MarkerSize',markerSize,'MarkerFaceColor',stagnationColor,...
            'MarkerEdgeColor','w');

        %% 图面优化
        title('电离源分布与极向停滞点', 'FontSize', fontSize+2);
        xlabel('R (m)', 'FontSize', fontSize);
        ylabel('Z (m)', 'FontSize', fontSize);
        axis equal tight;
        box on;
        grid on;
        set(ax, 'FontSize', fontSize, 'Layer','top');
        
        %% 区域裁剪
        if domain ~= 0
            setDomainLimits(ax, domain);
        end
        
        %% 添加算例标识
        annotation('textbox',[0.28 0.93 0.45 0.05],...
            'String',currentLabel,'EdgeColor','none',...
            'FontSize',fontSize-2,'HorizontalAlignment','center');
        
        %% 保存结果
        saveFigureWithTimestamp(fig, 'IonSource_Stagnation');
        hold(ax, 'off');
    end
    fprintf('\n>>> 所有算例处理完成\n');
end

%% ====================== 子函数 ======================
function [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma, gmtry, scaleFactor)
    % 计算二维电离源和极向速度分布
    [nx, ny] = size(gmtry.crx,1:2);
    ionSource2D = zeros(nx, ny);
    uPol2D = zeros(nx, ny);
    
    % 预加载数据提升性能
    sna_data = plasma.sna(:,:,:,4);    % 假设第4组分对应电离源
    na_data = plasma.na;
    
    for j = 1:ny
        for i = 1:nx
            % 电离源计算
            ionSource2D(i,j) = (sna_data(i,j,1) + sna_data(i,j,2).*na_data(i,j,4)) / scaleFactor;
            
            % 极向速度计算
            gammaPol = sum(plasma.fna_mdf(i,j,1,4:13),4);
            nImp = sum(na_data(i,j,4:13),3);
            if nImp > 0
                uPol2D(i,j) = gammaPol / nImp;
            else
                uPol2D(i,j) = 0;
            end
        end
    end
end

function stagnationMask = detect_poloidal_stagnation(uPol2D, jSOLrange)
    % 检测极向速度停滞点（uPol符号变化点）
    [nx, ny] = size(uPol2D);
    stagnationMask = false(nx, ny);
    jStart = max(1, jSOLrange(1));
    jEnd = min(ny, jSOLrange(2));
    
    % 向量化计算提高效率
    for j = jStart:jEnd
        uPolSlice = uPol2D(:,j);
        signChange = sign(uPolSlice(1:end-1)) .* sign(uPolSlice(2:end)) < 0;
        stagnationMask([signChange; false],j) = true;
    end
end

function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 通过四角坐标计算网格中心
    rCenter = mean(crx,3);
    zCenter = mean(cry,3);
end

function setDomainLimits(ax, domain)
    % 设置坐标轴显示范围
    switch domain
        case 1 % 上偏滤器
            xlim(ax, [1.30, 2.00]);
            ylim(ax, [0.50, 1.20]);
        case 2 % 下偏滤器
            xlim(ax, [1.30, 2.05]);
            ylim(ax, [-1.15, -0.40]);
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
    % 带时间戳保存图窗
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fileName = sprintf('%s_%s', baseName, timestamp);
    
    % 保存为FIG和PNG双格式
    saveas(figHandle, [fileName '.fig']);
    print(figHandle, [fileName '.png'], '-dpng', '-r300'); 
    fprintf('图窗已保存: %s.*\n', fileName);
end