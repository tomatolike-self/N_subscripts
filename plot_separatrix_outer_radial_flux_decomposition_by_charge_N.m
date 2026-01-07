function plot_separatrix_outer_radial_flux_decomposition_by_charge_N(all_radiationData)
% =========================================================================
% plot_separatrix_outer_radial_flux_decomposition_by_charge_N
%   Separatrix外主SOL区域：按价态分解径向通量（N杂质）
% =========================================================================
%
% 功能描述：
%   - 对 N^{1+}...N^{7+} 的7个价态分别分析separatrix处的径向通量
%   - 将总通量分解为：cvla对流项 + ExB对流项 + 扩散类项（Diff-like）
%   - 绘制Core Influx/Outflux/Net三个子图，每个子图按价态分组对比四类通量
%
% 输入：
%   - all_radiationData : cell数组或struct，包含SOLPS仿真数据
%     每个元素需包含 radData.gmtry 和 radData.plasma 结构体
%
% 输出：
%   - 1×3布局的柱状图figure（Core Influx / Core Outflux / Net Flux）
%   - 自动保存带时间戳的.fig文件
%   - 命令行输出各价态通量分解详情
%
% 使用示例：
%   plot_separatrix_outer_radial_flux_decomposition_by_charge_N(all_radiationData)
%
% 依赖函数/工具箱：
%   - 无
%
% 注意事项：
%   - R2019a兼容（使用subplot替代tiledlayout）
%   - 通量分解基于b2tfnb.F源码结构的近似重构：
%     * Total: fna_mdf（径向通量，b2fplasmf输出）
%     * cvla: cvla × n_face（cvla对流项，描述平行流在径向的投影贡献）
%     * ExB: vExB × Ay × n_face（ExB漂移对流项，描述E×B漂移输运）
%     * Diff-like: -con_mdf×Δn - cdpa×Δpb - fnaPSch（非对流项）
%   - 默认使用drift_style=1（与b2mn.dat中b2tfnb_drift_style=1一致）
%   - 近似假设：bottom neighbor用(ix,iy-1)近似，在X点附近可能有微小偏差
% =========================================================================

%% 常量定义（EAST标准网格）
MAIN_SOL_POL_RANGE = 26:73;  % 主SOL极向网格范围（避开私有通量区和X点）
SEPARATRIX_RAD_POS = 14;     % 分离面径向位置（cell与其bottom neighbor之间的面）
DIR_RADIAL = 2;              % 径向分量索引：1=极向面，2=径向面（南面）

% N杂质价态索引（与N脚本系统一致）
N_SPECIES_START = 4;         % N1+在plasma.na中的索引
MAX_N_CHARGE = 7;            % N1+...N7+

% b2tfnb.F源码参数（与b2mn.dat设置一致）
DRIFT_STYLE = 1;             % drift_style=1: flo_mdf = cvla + vaecrb × A_y
USE_HYBRID = true;           % 使用hybr(flo_mdf, cdna)计算con_mdf
INCLUDE_CDPA_AND_PSCH = true; % 将cdpa和fnaPSch计入扩散类项

% 绘图属性
TICK_FONT_SIZE = 20;
LABEL_FONT_SIZE = 24;
LEGEND_FONT_SIZE = 16;

%% 输入适配：允许单算例struct或cell数组
if iscell(all_radiationData)
    cases = all_radiationData;
else
    cases = {all_radiationData};
end

%% 逐算例处理
for i_case = 1:numel(cases)
    radData = cases{i_case};
    
    % 检查必需字段
    if ~isfield(radData, 'gmtry') || ~isfield(radData, 'plasma')
        warning('Input case %d missing gmtry/plasma. Skipping.', i_case);
        continue;
    end
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    
    % 获取目录名（用于标题和文件名）
    dirName = '';
    if isfield(radData, 'dirName')
        dirName = radData.dirName;
    end
    
    %% 基本字段检查
    % plasma必需字段：fna_mdf为总径向通量，na为密度，cdna为扩散系数等
    required_plasma = {'fna_mdf', 'na', 'cvla', 'vaecrb', 'cdna', 'te', 'ti'};
    missing_plasma = required_plasma(~isfield(plasma, required_plasma));
    if ~isempty(missing_plasma)
        warning('Case %d missing plasma fields: %s. Skipping.', i_case, strjoin(missing_plasma, ', '));
        continue;
    end
    
    % gmtry必需字段：vol为体积，hy为径向网格尺寸，qz为几何因子
    required_gmtry = {'vol', 'hy', 'qz'};
    missing_gmtry = required_gmtry(~isfield(gmtry, required_gmtry));
    if ~isempty(missing_gmtry)
        warning('Case %d missing gmtry fields: %s. Skipping.', i_case, strjoin(missing_gmtry, ', '));
        continue;
    end
    
    % 网格尺寸检查
    [nx_tot, ny_tot] = size(gmtry.vol);
    if SEPARATRIX_RAD_POS < 2 || SEPARATRIX_RAD_POS > ny_tot
        warning('SEPARATRIX_RAD_POS=%d out of range (ny=%d). Skipping case.', SEPARATRIX_RAD_POS, ny_tot);
        continue;
    end
    if max(MAIN_SOL_POL_RANGE) > nx_tot
        warning('MAIN_SOL_POL_RANGE exceeds nx=%d. Skipping case.', nx_tot);
        continue;
    end
    
    %% 初始化通量存储数组
    % 四类通量：Total（总通量）, cvla（cvla对流项）, ExB（ExB对流项）, Diff（扩散类项）
    % Core Influx（<0）和 Core Outflux（>0）分别存储
    total_in_sum = zeros(MAX_N_CHARGE, 1);
    cvla_in_sum = zeros(MAX_N_CHARGE, 1);
    exb_in_sum = zeros(MAX_N_CHARGE, 1);
    diff_in_sum = zeros(MAX_N_CHARGE, 1);
    
    total_out_sum = zeros(MAX_N_CHARGE, 1);
    cvla_out_sum = zeros(MAX_N_CHARGE, 1);
    exb_out_sum = zeros(MAX_N_CHARGE, 1);
    diff_out_sum = zeros(MAX_N_CHARGE, 1);
    
    % 网格索引
    ix = MAIN_SOL_POL_RANGE(:);  % 极向网格索引（列向量）
    iy = SEPARATRIX_RAD_POS;     % 径向位置：当前cell
    iyS = iy - 1;                % 径向位置：bottom neighbor (S = south)
    
    % 计算hy1：径向网格尺寸 × 几何因子（与b2tfnb.F一致）
    hy1 = gmtry.hy .* gmtry.qz(:, :, 2);
    
    %% 逐价态计算通量分解
    for q = 1:MAX_N_CHARGE
        species_idx = N_SPECIES_START + q - 1;  % N1+ -> 4, N7+ -> 10
        
        % 检查物种索引是否在数据范围内
        if species_idx > size(plasma.na, 3) || species_idx > size(plasma.fna_mdf, 4)
            continue;
        end
        
        % ====== 1. 总通量（直接从b2fplasmf输出读取） ======
        % fna_mdf(:,:,2,:) 是径向（南面）通量，单位：particles/s
        gamma_total = plasma.fna_mdf(ix, iy, DIR_RADIAL, species_idx);
        
        % ====== 2. 计算面两侧密度及密度差 ======
        % P: 当前cell (ix, iy)
        % S: bottom neighbor (ix, iy-1)
        nP = plasma.na(ix, iy, species_idx);
        nS = plasma.na(ix, iyS, species_idx);
        nFace = 0.5 * (nP + nS);  % 面处密度（算术平均）
        dn = (nP - nS);           % 密度差（用于扩散项计算）
        
        % ====== 3. 获取cvla和ExB速度分量 ======
        % cvla: 平行流在径向的投影（来自plasma.cvla）
        % vExB: E×B漂移速度的径向分量（来自plasma.vaecrb）
        cvla_y = plasma.cvla(ix, iy, DIR_RADIAL, species_idx);
        vExB_y = plasma.vaecrb(ix, iy, DIR_RADIAL, species_idx);
        
        % ====== 4. 计算ExB项的有效面积因子 ======
        % 根据drift_style=1的公式：exb_flow = vaecrb × A_y
        % 其中 A_y = (volP + volS) / (hy1P + hy1S)
        if DRIFT_STYLE == 1
            % drift_style=1: 使用体积和hy1计算有效面积
            volP = gmtry.vol(ix, iy);
            volS = gmtry.vol(ix, iyS);
            hy1P = hy1(ix, iy);
            hy1S = hy1(ix, iyS);
            denom = (hy1P + hy1S);
            % 避免除零：设为NaN后面会被omitnan处理
            denom(abs(denom) < eps) = NaN;
            Ay = (volP + volS) ./ denom;
            exb_flow = vExB_y .* Ay;  % ExB速度 × 有效面积
        elseif DRIFT_STYLE == 2
            % drift_style=2: 直接使用gs面积
            if ~isfield(gmtry, 'gs')
                error('DRIFT_STYLE=2 requires gmtry.gs field.');
            end
            area_y = gmtry.gs(ix, iy, 2);
            exb_flow = vExB_y .* area_y;
        else
            error('Unsupported DRIFT_STYLE=%d (expected 1 or 2).', DRIFT_STYLE);
        end
        
        % ====== 5. 分别计算cvla对流项和ExB对流项 ======
        % Γ_cvla = cvla × n_face（平行流在径向的投影贡献）
        gamma_cvla = cvla_y .* nFace;
        % Γ_ExB = exb_flow × n_face（E×B漂移输运贡献）
        gamma_exb = exb_flow .* nFace;
        
        % ====== 6. 计算con_mdf（有效扩散系数） ======
        % 默认使用hybrid函数：hybr(F,D) = max(D, |F|/2, sqrt(D^2 + F^2/4))
        % 这里F = flo_mdf = cvla + exb_flow，D = cdna
        cdna_y = plasma.cdna(ix, iy, DIR_RADIAL, species_idx);
        if USE_HYBRID
            flo_mdf = cvla_y + exb_flow;  % 总对流场
            term1 = cdna_y;
            term2 = abs(flo_mdf) / 2;
            term3 = sqrt(cdna_y.^2 + flo_mdf.^2 / 4);
            con_mdf = max(term1, max(term2, term3));
        else
            con_mdf = cdna_y;
        end
        
        % ====== 7. 扩散类项：Γ_diff = -con_mdf × Δn（+ 额外项） ======
        gamma_diff_like = -con_mdf .* dn;
        
        % 额外非对流项：-cdpa×(pbP-pbS) - fnaPSch
        if INCLUDE_CDPA_AND_PSCH
            % 热压力驱动项：cdpa × Δpb
            if isfield(plasma, 'cdpa')
                cdpa_y = plasma.cdpa(ix, iy, DIR_RADIAL, species_idx);
                teP = plasma.te(ix, iy);
                teS = plasma.te(ix, iyS);
                tiP = plasma.ti(ix, iy);
                tiS = plasma.ti(ix, iyS);
                % pb = n × (Z×Te + Ti)，其中Z=q为电荷数
                pbP = nP .* (q * teP + tiP);
                pbS = nS .* (q * teS + tiS);
                gamma_diff_like = gamma_diff_like - cdpa_y .* (pbP - pbS);
            end
            % Pfirsch-Schlüter项（如果存在）
            if isfield(plasma, 'fnaPSch')
                gamma_diff_like = gamma_diff_like - plasma.fnaPSch(ix, iy, DIR_RADIAL, species_idx);
            end
        end
        
        % ====== 8. 按符号分类：Core Influx(<0) 和 Core Outflux(>0) ======
        % 负值表示进入芯部，正值表示离开芯部
        total_in_sum(q) = sum(gamma_total(gamma_total < 0), 'omitnan');
        cvla_in_sum(q) = sum(gamma_cvla(gamma_cvla < 0), 'omitnan');
        exb_in_sum(q) = sum(gamma_exb(gamma_exb < 0), 'omitnan');
        diff_in_sum(q) = sum(gamma_diff_like(gamma_diff_like < 0), 'omitnan');
        
        total_out_sum(q) = sum(gamma_total(gamma_total > 0), 'omitnan');
        cvla_out_sum(q) = sum(gamma_cvla(gamma_cvla > 0), 'omitnan');
        exb_out_sum(q) = sum(gamma_exb(gamma_exb > 0), 'omitnan');
        diff_out_sum(q) = sum(gamma_diff_like(gamma_diff_like > 0), 'omitnan');
    end
    
    %% 绘图：1×3布局（使用subplot兼容R2019a）
    % 左：Core Influx，中：Core Outflux，右：Net Flux（In+Out）
    fig = figure('NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 20, 7]);
    
    % 颜色定义：四类通量
    % 灰色-Total, 绿色-ExB, 红色-Diff-like, 蓝色-cvla
    colors = [
        0.3, 0.3, 0.3;   % 灰色 - Total
        0.0, 0.80, 0.40; % 绿色 - ExB
        0.85, 0.10, 0.10; % 红色 - Diff-like
        0.0, 0.45, 0.90  % 蓝色 - cvla
        ];
    
    % 价态标签
    charge_labels = {'N$^{1+}$', 'N$^{2+}$', 'N$^{3+}$', 'N$^{4+}$', 'N$^{5+}$', 'N$^{6+}$', 'N$^{7+}$'};
    
    % ====== 计算Net Flux（In + Out，即总通量不分正负） ======
    total_net_sum = total_in_sum + total_out_sum;
    cvla_net_sum = cvla_in_sum + cvla_out_sum;
    exb_net_sum = exb_in_sum + exb_out_sum;
    diff_net_sum = diff_in_sum + diff_out_sum;
    
    % ====== 左子图：Core Influx ======
    subplot(1, 3, 1);
    Y_in = [total_in_sum, exb_in_sum, diff_in_sum, cvla_in_sum];
    b1 = bar(1:MAX_N_CHARGE, Y_in, 'grouped');
    for j = 1:numel(b1)
        set(b1(j), 'FaceColor', colors(j, :), 'EdgeColor', 'k', 'LineWidth', 1.2);
    end
    grid on;
    ax1 = gca;
    set(ax1, 'FontName', 'Times New Roman', 'FontSize', TICK_FONT_SIZE, 'LineWidth', 1.8);
    set(ax1, 'TickLabelInterpreter', 'latex');
    xticks(1:MAX_N_CHARGE);
    xticklabels(charge_labels);
    xlabel('Charge state', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    ylabel('$\Gamma_{\mathrm{r}}$ (s$^{-1}$)', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    title('Core Influx', 'Interpreter', 'none', 'FontSize', LABEL_FONT_SIZE);
    hold on;
    line(xlim, [0 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.0);
    hold off;
    
    % ====== 中子图：Core Outflux ======
    subplot(1, 3, 2);
    Y_out = [total_out_sum, exb_out_sum, diff_out_sum, cvla_out_sum];
    b2 = bar(1:MAX_N_CHARGE, Y_out, 'grouped');
    for j = 1:numel(b2)
        set(b2(j), 'FaceColor', colors(j, :), 'EdgeColor', 'k', 'LineWidth', 1.2);
    end
    grid on;
    ax2 = gca;
    set(ax2, 'FontName', 'Times New Roman', 'FontSize', TICK_FONT_SIZE, 'LineWidth', 1.8);
    set(ax2, 'TickLabelInterpreter', 'latex');
    xticks(1:MAX_N_CHARGE);
    xticklabels(charge_labels);
    xlabel('Charge state', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    title('Core Outflux', 'Interpreter', 'none', 'FontSize', LABEL_FONT_SIZE);
    hold on;
    line(xlim, [0 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.0);
    hold off;
    
    % ====== 右子图：Net Flux（In + Out） ======
    subplot(1, 3, 3);
    Y_net = [total_net_sum, exb_net_sum, diff_net_sum, cvla_net_sum];
    b3 = bar(1:MAX_N_CHARGE, Y_net, 'grouped');
    for j = 1:numel(b3)
        set(b3(j), 'FaceColor', colors(j, :), 'EdgeColor', 'k', 'LineWidth', 1.2);
    end
    grid on;
    ax3 = gca;
    set(ax3, 'FontName', 'Times New Roman', 'FontSize', TICK_FONT_SIZE, 'LineWidth', 1.8);
    set(ax3, 'TickLabelInterpreter', 'latex');
    xticks(1:MAX_N_CHARGE);
    xticklabels(charge_labels);
    xlabel('Charge state', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    title('Net Flux (In+Out)', 'Interpreter', 'none', 'FontSize', LABEL_FONT_SIZE);
    hold on;
    line(xlim, [0 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.0);
    hold off;
    
    % 图例（放在右子图，4类通量）
    lg = legend(ax3, {'Total (fna\_mdf)', 'ExB', 'Diff-like', 'cvla'}, ...
        'Interpreter', 'latex', 'FontSize', LEGEND_FONT_SIZE, 'Location', 'best');
    set(lg, 'Box', 'on');
    
    % ====== 统一Y轴范围，便于三个子图对比 ======
    y_all = [Y_in(:); Y_out(:); Y_net(:)];
    y_all = y_all(isfinite(y_all));
    if ~isempty(y_all) && any(y_all ~= 0)
        ypad = 0.08 * max(abs(y_all));
        ylim_range = [min([0; y_all]) - ypad, max([0; y_all]) + ypad];
        ylim(ax1, ylim_range);
        ylim(ax2, ylim_range);
        ylim(ax3, ylim_range);
    end
    
    % ====== 总标题（使用annotation创建，R2019a兼容） ======
    if ~isempty(dirName)
        title_str = sprintf('Separatrix radial flux by charge state (N): %s', dirName);
    else
        title_str = 'Separatrix radial flux (Main SOL) by charge state (N)';
    end
    annotation(fig, 'textbox', [0.1, 0.95, 0.8, 0.05], ...
        'String', title_str, 'Interpreter', 'none', ...
        'FontSize', LABEL_FONT_SIZE, 'FontName', 'Times New Roman', ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
    
    %% 命令行输出：打印各价态通量分解详情
    fprintf('\n=== Case %d: %s ===\n', i_case, dirName);
    fprintf('iy=%d, pol=[%d..%d], drift_style=%d, hybrid=%d, include_cdpa_psch=%d\n', ...
        iy, MAIN_SOL_POL_RANGE(1), MAIN_SOL_POL_RANGE(end), DRIFT_STYLE, USE_HYBRID, INCLUDE_CDPA_AND_PSCH);
    for q = 1:MAX_N_CHARGE
        fprintf('N%1d+: In  total=% .3e  cvla=% .3e  exb=% .3e  diff=% .3e | Out total=% .3e  cvla=% .3e  exb=% .3e  diff=% .3e\n', ...
            q, total_in_sum(q), cvla_in_sum(q), exb_in_sum(q), diff_in_sum(q), ...
            total_out_sum(q), cvla_out_sum(q), exb_out_sum(q), diff_out_sum(q));
    end
    
    %% 保存Figure
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    if isempty(dirName)
        tag = sprintf('case%02d', i_case);
    else
        % 清理文件名中的非法字符
        tag = regexprep(dirName, '[^a-zA-Z0-9_\-]+', '_');
        if length(tag) > 50
            tag = tag(1:50);  % 限制长度
        end
    end
    fname = sprintf('SeparatrixFlux_N_ByCharge_%s_%s.fig', tag, timestamp);
    savefig(fig, fname);
    fprintf('Figure saved: %s\n', fname);
end

end
