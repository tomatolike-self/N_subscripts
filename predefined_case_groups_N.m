function groups = predefined_case_groups_N()
% ========================================================================
% 预定义的N杂质算例组配置函数
% 基于实际的N杂质算例目录结构
% ========================================================================
%
% 返回值：
%   groups - 包含预定义算例组的结构体
%     .fav_BT   - 有利BT方向的4个N浓度子组 (normal方向)
%     .unfav_BT - 不利BT方向的4个N浓度子组 (reversed方向)
%     .combined - 合并组（包含所有8个子组）
%
% 使用方法：
%   groups = predefined_case_groups_N();
%   selected_groups = groups.fav_BT;  % 选择有利BT组
%
% 注意：
%   - 基于实际的81574_D+N目录结构
%   - normal方向对应fav BT，reversed方向对应unfav BT
%   - 根据算例名称中的N浓度标识进行分类
%   - 路径格式与实际服务器上的目录结构匹配
% ========================================================================

% 调用实际的配置函数
groups = predefined_case_groups_N_real();

end
