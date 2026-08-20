function study = run_routeA_focused_vsh_v5_dynamic_control()
% Run two dynamic cEGR step cases through the formal runner.

scriptDir = fileparts(mfilename('fullpath'));
sharedDir = fullfile(scriptDir, '..', 'RouteA_GasMixture_Derived');
addpath(scriptDir, sharedDir);

[totalStudy, ~, ~, ~] = ...
    routeA_focused_external240kw_cegr_matrix_case_factory();
low = findCase(totalStudy.cases, "external240_total_flow_fixed_j0p1_R0p000");
mid = findCase(totalStudy.cases, "external240_total_flow_fixed_j0p4_R0p000");
x01 = 0.1 / 1.1;
x02 = 0.2 / 1.2;
profile = [0 0; 180 0; 180.001 x01; 360 x01; ...
    360.001 x02; 600 x02];

low.caseId = "V5_dynamic_low_j0p1";
low.description = "V5 dynamic cEGR low-load R=0_to_0p1_to_0p2";
low.cegr.enabled = true;
low.cegr.controlMode = 1;
low.cegr.targetInputMode = 1;
low.cegr.targetRatio = x02;
low.cegr.targetRecirculationR = 0.2;
low.cegr.profile = profile;

mid.caseId = "V5_dynamic_mid_j0p4";
mid.description = "V5 dynamic cEGR mid-load R=0_to_0p1_to_0p2";
mid.cegr.enabled = true;
mid.cegr.controlMode = 1;
mid.cegr.targetInputMode = 1;
mid.cegr.targetRatio = x02;
mid.cegr.targetRecirculationR = 0.2;
mid.cegr.profile = profile;

resultFile = fullfile(scriptDir, '..', '..', '02_结果', ...
    'RouteA_Cathode_cEGR_Focused', 'outputs', '20260820_vsh_validation', ...
    'RouteA_VSH_V5_dynamic_control_600s_20260820.mat');
cfg = struct( ...
    'modelId', "self_humidifying", ...
    'calculationType', "steady", ...
    'cases', [low; mid], ...
    'researchDuration_s', 600, ...
    'tailLogicalWindow_s', [540 600], ...
    'steadyWindowDuration_s', 60, ...
    'retainSimulationOutputs', true, ...
    'executionMode', "serial", ...
    'parallel', struct('poolProfile', "local", 'workerCount', 1, ...
        'showProgress', false, 'useFastRestart', false), ...
    'resultFile', string(resultFile), ...
    'cegrScreenContract', totalStudy.cegrScreenContract);

study = run_routeA_focused_study(cfg);
dynamicAudit = auditDynamicOutputs(study);
study.dynamicAudit = dynamicAudit;
routeA_focused_study = study; %#ok<NASGU>
save(resultFile, 'routeA_focused_study', '-v7.3');
assignin('base', 'routeA_focused_v5_study', study);
fprintf('V5_DONE cases=%d completed=%d passed=%d result=%s\n', ...
    numel(study.cases), sum([study.cases.simCompleted]), ...
    sum([study.cases.passed]), resultFile);
for idx = 1:numel(dynamicAudit)
    fprintf('V5_CASE %s logs=%s response=%s tailR=%.6g area=%.6g pstack=%.6g\n', ...
        dynamicAudit(idx).caseId, dynamicAudit(idx).loggedSignalStatus, ...
        dynamicAudit(idx).responseStatus, dynamicAudit(idx).tailRecirculationR, ...
        dynamicAudit(idx).tailValveAreaFraction, ...
        dynamicAudit(idx).tailStackOutletPressure_MPa);
end
end
function audit = auditDynamicOutputs(study)
audit = repmat(auditTemplate(), numel(study.cases), 1);
for idx = 1:numel(study.cases)
    item = study.cases(idx);
    audit(idx).caseId = string(item.caseId);
    audit(idx).simCompleted = logical(item.simCompleted);
    audit(idx).steadyPassed = logical(getNested(item, ...
        {'steadyPassed'}, false));
    audit(idx).tailRecirculationR = getNested(item, ...
        {'performance', 'cegr', 'actualRatioFreshBasis'}, NaN);
    audit(idx).tailValveAreaFraction = getNested(item, ...
        {'performance', 'cegr', 'valveAreaFraction'}, NaN);
    audit(idx).tailStackOutletPressure_MPa = getNested(item, ...
        {'performance', 'pressure', 'chain', 'p_stack_out_MPa'}, NaN);
    if idx > numel(study.outputs) || isempty(study.outputs{idx})
        audit(idx).loggedSignalStatus = "not_retained";
        audit(idx).responseStatus = "not_evaluable";
        continue;
    end
    out = study.outputs{idx};
    names = string(out.logsout.getElementNames);
    audit(idx).loggedSignalStatus = "logsout_" + string(numel(names)) + "_signals";
    audit(idx).loggedSignalNames = names;
    if any(contains(names, "egr")) || any(contains(names, "EGR"))
        audit(idx).responseStatus = "dynamic_signal_family_present";
    else
        audit(idx).responseStatus = "dynamic_signal_family_not_named_in_logsout";
    end
end
end

function item = findCase(cases, caseId)
index = find(string({cases.caseId}) == string(caseId), 1);
if isempty(index)
    error('RouteA:FocusedV5Case', 'V5 source case not found: %s', caseId);
end
item = cases(index);
end

function value = getNested(source, path, default)
value = source;
for idx = 1:numel(path)
    if ~isstruct(value) || ~isfield(value, path{idx}) || ...
            isempty(value.(path{idx}))
        value = default;
        return;
    end
    value = value.(path{idx});
end
end

function value = auditTemplate()
value = struct('caseId', "", 'simCompleted', false, ...
    'steadyPassed', false, 'tailRecirculationR', NaN, ...
    'tailValveAreaFraction', NaN, ...
    'tailStackOutletPressure_MPa', NaN, ...
    'loggedSignalStatus', "not_checked", ...
    'loggedSignalNames', strings(0, 1), ...
    'responseStatus', "not_checked");
end
