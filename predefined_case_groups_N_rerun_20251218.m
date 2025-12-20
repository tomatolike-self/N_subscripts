function groups = predefined_case_groups_N_rerun_20251218()
% ========================================================================
% Predefined case groups for N impurity (RERUN version, 2025-12-18)
%
% Notes:
%   - This file is HARD-CODED (no txt parsing at runtime).
%   - Grouping/order follow predefined_case_groups_N_real.m (pre-rerun).
%   - Rerun directories contain _input suffixes.
% ========================================================================

base_path = '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N';
groups = struct();

% fav_BT group 1
groups.fav_BT{1} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p15e22_target1_target1_input2');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_input2');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_input2');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_input2');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p08e22_target1_target1_input2');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_input2');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_input2');
};

% fav_BT group 2
groups.fav_BT{2} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_target1_target1_input1');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_target1_input1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2_input1');
};

% fav_BT group 3
groups.fav_BT{3} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_N1p5_target1_target1_input1');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_N1p5_target1_target1_input1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_input1');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2_N1p5_target1_target1_input1');
};

% fav_BT group 4
groups.fav_BT{4} = {
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_input1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_Flux1p15e22_target1_target1_input1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2_input1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2_Flux1p08e22_target1_target1_input1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_input1');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_input1');
};

% unfav_BT group 1
groups.unfav_BT{1} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p26e22_target1_target1_input1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5_input1');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_input1');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p20e22_target1_target1_input1');
    fullfile(base_path, '10mw_flux_1p3000e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_input1');
    fullfile(base_path, '10mw_flux_1p3000e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_target1_target1_input1');
};

% unfav_BT group 2
groups.unfav_BT{2} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_target1_target1_input1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_input1');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_target1_target1_input1');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_input1');
    fullfile(base_path, '10mw_flux_1p3080e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_input1');
};

% unfav_BT group 3
groups.unfav_BT{3} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N1p5_target1_target1_input1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_N1p5_target1_target1_input1');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N1p5_target1_target1_input1');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1_input1');
};

% unfav_BT group 4
groups.unfav_BT{4} = {
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2_input3');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2_input4');
};

groups.combined = [groups.fav_BT, groups.unfav_BT];

end
