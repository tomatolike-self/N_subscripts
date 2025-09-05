function plot_ionization_source()
    % =========================================================================
    % 功能：
    %   绘制电离源分布图
    %   使用MATLAB默认设置显示数据分布
    %   能够处理第一行和第一列为编号而非物理数据的情况
    % =========================================================================

    % 读取数据（处理带有行列标签的格式）
    % 首先读取完整数据文件
    fileID = fopen('b2stbr_sna_eir003.dat', 'r');
    if fileID == -1
        error('无法打开文件，请检查文件名和路径');
    end
    
    % 读取全部数据为文本行
    allLines = textscan(fileID, '%s', 'Delimiter', '\n');
    allLines = allLines{1};
    fclose(fileID);
    
    % 获取第一行并解析为数值数组（可能包含编号）
    headerData = sscanf(allLines{1}, '%f');
    
    % 判断第一个数是否为行列编号的起始点（通常为非物理意义的数值）
    % 获取真正的R坐标（跳过第一个数，如果它是编号）
    r_coords = headerData(2:end); % 假设第一列为编号，跳过第一个数
    
    % 预分配空间来存储数据和Z坐标
    numRows = length(allLines) - 1; % 减去标题行
    numCols = length(r_coords);
    data = zeros(numRows, numCols);
    z_coords = zeros(numRows, 1);
    
    % 逐行读取数据，提取Z坐标和数值（跳过第一行）
    for i = 1:numRows
        % 解析行数据
        lineData = sscanf(allLines{i+1}, '%f');
        if ~isempty(lineData)
            % 提取Z坐标（第二个数，跳过行编号）
            z_coords(i) = lineData(2);
            % 提取该行的实际数据值（跳过前两个值：行编号和Z坐标）
            data(i, :) = lineData(3:end)';
        end
    end
    
    % 转置数据矩阵确保正确的方向
    data = flipud(data);  % 上下翻转以匹配Z从低到高
    z_coords = flipud(z_coords);  % 同样翻转Z坐标
    
    % 创建R和Z坐标网格
    [R_grid, Z_grid] = meshgrid(r_coords, z_coords);
    
    % 创建图形
    figure('Name', '电离源分布图', 'NumberTitle', 'off', ...
           'Color', 'w', 'Units', 'pixels', 'Position', [100 50 1400 1000]);
    
    % 设置全局字体
    set(gcf, 'DefaultTextFontName', 'Times New Roman');
    set(gcf, 'DefaultAxesFontName', 'Times New Roman');
    set(gcf, 'DefaultAxesFontSize', 16);
    set(gcf, 'DefaultTextFontSize', 16);
    
    % 直接绘制电离源分布，不进行对数转换
    h = pcolor(R_grid, Z_grid, data);
    shading interp;
    colormap(jet);
    
    % 添加默认颜色条
    colorbar;
    
    % 设置坐标轴标签
    xlabel('R (m)', 'FontSize', 16, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
    ylabel('Z (m)', 'FontSize', 16, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
    
    % 设置标题
    title('电离源分布图', 'FontSize', 18, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
    
    % 设置坐标轴属性
    axis equal tight;
    box on;
    grid on;
    
    % 保存图形
    saveas(gcf, '电离源分布图.png');
    saveas(gcf, '电离源分布图.fig');
    
    fprintf('图形已保存为 电离源分布图.png 和 .fig\n');
    
    % 显示数据统计信息
    fprintf('数据统计信息：\n');
    fprintf('矩阵大小: [%d x %d]\n', size(data));
    fprintf('最小值: %.4e\n', min(data(:)));
    fprintf('最大值: %.4e\n', max(data(:)));
    fprintf('Z坐标范围: [%.2f, %.2f]\n', min(z_coords), max(z_coords));
    fprintf('R坐标范围: [%.2f, %.2f]\n', min(r_coords), max(r_coords));
end 