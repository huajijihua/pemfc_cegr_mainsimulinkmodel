function study = run_routeA_focused_vsh_v6_zero_crossing_sensitivity(reuseExistingGroupResults)
% Run the bounded V6 zero-crossing sensitivity study.
%
% The formal simulation core remains run_routeA_focused_study. This entry
% point only assembles the seven declared sensitivity groups, each at the
% two V2 failure loads, and combines their auditable results. No model
% structure, assertion, or negative-mass-fraction protection is changed.

scriptDir = fileparts(mfilename('fullpath'));
sharedDir = fullfile(scriptDir, '..', 'RouteA_GasMixture_Derived');
addpath(scriptDir, sharedDir);
if nargin < 1
    reuseExistingGroupResults = false;
end

resultFile = fullfile(scriptDir, '..', '..', '02_结果', ...
    'RouteA_Cathode_cEGR_Focused', 'outputs', '20260820_vsh_validation', ...
    'RouteA_VSH_zero_crossing_sensitivity_600s_20260820.mat');
if ~isfolder(fileparts(resultFile))
    mkdir(fileparts(resultFile));
end

[baseCases, reference] = routeA_focused_external240kw_case_factory([1.1 1.5]);
defaults = routeA_focused_parameter_defaults("self_humidifying");
groups = groupDefinitions(defaults);
groupResults = repmat(groupResultTemplate(), numel(groups), 1);
allRows = repmat(rowTemplate(), 0, 1);

for groupIndex = 1:numel(groups)
    group = groups(groupIndex);
    cases = mutateCases(baseCases, group);
    groupResultFile = fullfile(fileparts(resultFile), ...
        "RouteA_VSH_V6_group_" + group.id + "_600s_20260820.mat");
    cfg = struct( ...
        'modelId', "self_humidifying", ...
        'calculationType', "steady", ...
        'cases', cases, ...
        'researchDuration_s', 600, ...
        'tailLogicalWindow_s', [540 600], ...
        'steadyWindowDuration_s', 60, ...
        'retainSimulationOutputs', false, ...
        'executionMode', "parallel", ...
        'parallel', struct('poolProfile', "local", 'workerCount', 4, ...
            'showProgress', true, 'useFastRestart', false), ...
        'solver', group.solver, ...
        'relativeTolerance', group.relativeTolerance, ...
        'absoluteTolerance', group.absoluteTolerance, ...
        'studyMaxStep_s', group.maxStep_s, ...
        'resultFile', string(groupResultFile));

    if reuseExistingGroupResults && isfile(groupResultFile)
        loadedGroup = load(groupResultFile, 'routeA_focused_study');
        groupStudy = loadedGroup.routeA_focused_study;
        fprintf('V6_GROUP_REUSE group=%s file=%s\n', group.id, groupResultFile);
    else
        fprintf(['V6_GROUP_START group=%s cases=%d solver=%s RelTol=%g ', ...
            'AbsTol=%g MaxStep=%g Kp=%g Ki=%g flowFactor=%g\n'], ...
            group.id, numel(cases), group.solver, group.relativeTolerance, ...
            group.absoluteTolerance, group.maxStep_s, group.Kp, group.Ki, ...
            group.flowFactor);
        groupStudy = run_routeA_focused_study(cfg);
    end
    rows = summarizeGroup(groupStudy, group, reference);
    allRows = [allRows; rows]; %#ok<AGROW>

    groupResults(groupIndex).groupId = group.id;
    groupResults(groupIndex).label = group.label;
    groupResults(groupIndex).study = groupStudy;
    groupResults(groupIndex).rows = rows;
    groupResults(groupIndex).simCompleted = sum([rows.simCompleted]);
    groupResults(groupIndex).localNumericsPassed = ...
        sum([rows.localNumericsPassed]);
    groupResults(groupIndex).zeroCrossingFailureCount = sum( ...
        contains([rows.failureCategory], "zero_crossing") | ...
        contains(lower([rows.errorMessage]), "zero-crossing"));
    fprintf(['V6_GROUP_DONE group=%s completed=%d passed=%d ', ...
        'zeroCrossingFailures=%d\n'], group.id, ...
        groupResults(groupIndex).simCompleted, ...
        groupResults(groupIndex).localNumericsPassed, ...
        groupResults(groupIndex).zeroCrossingFailureCount);
end

decision = classifyStudy(allRows);
study = struct( ...
    'schemaVersion', "RouteA_VSH_ZeroCrossingSensitivity_v01", ...
    'timestamp', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
    'studyId', "V6_zero_crossing_sensitivity", ...
    'modelId', "self_humidifying", ...
    'model', "PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01", ...
    'modelFile', "04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx", ...
    'sourceV2ResultFile', "RouteA_VSH_V2_external240_baseline_600s_20260820.mat", ...
    'reference', reference, ...
    'scope', "two V2 zero-crossing loads j=1.1 and 1.5 A/cm^2; gas-phase focused boundary only", ...
    'initializationPolicy', "cold_start_only", ...
    'researchDuration_s', 600, ...
    'tailLogicalWindow_s', [540 600], ...
    'maxCaseCount', 14, ...
    'groupDefinitions', groups, ...
    'groups', groupResults, ...
    'cases', allRows, ...
    'decision', decision, ...
    'protectionPolicy', "no assertion relaxation; no negative mass-fraction clipping; no model-structure edits", ...
    'resultFile', string(resultFile));

routeA_vsh_v6_sensitivity = study;
routeA_focused_study = study;
save(resultFile, 'routeA_vsh_v6_sensitivity', 'routeA_focused_study', '-v7.3');
assignin('base', 'routeA_vsh_v6_sensitivity', study);
fprintf('V6_DONE cases=%d completed=%d passed=%d decision=%s result=%s\n', ...
    numel(allRows), sum([allRows.simCompleted]), ...
    sum([allRows.localNumericsPassed]), decision.classification, resultFile);
end

function groups = groupDefinitions(defaults)
solver = string(defaults.solver.solver);
relTol = defaults.solver.relTol;
absTol = defaults.solver.absTol;
maxStep = defaults.solver.maxStep_s;

groups = repmat(groupTemplate(), 7, 1);
groups(1) = makeGroup("B", "baseline_reproduction", solver, relTol, absTol, maxStep, 5, .5, 1.0, "baseline");
groups(2) = makeGroup("S1", "solver_maxstep_0p5", solver, relTol, absTol, .5, 5, .5, 1.0, "solver");
groups(3) = makeGroup("S2", "solver_tighter_tolerance", solver, 1e-4, 1e-4, maxStep, 5, .5, 1.0, "solver");
groups(4) = makeGroup("C1", "control_slow_half_gain", solver, relTol, absTol, maxStep, 2.5, .25, 1.0, "control");
groups(5) = makeGroup("C2", "control_fast_double_gain", solver, relTol, absTol, maxStep, 10, 1.0, 1.0, "control");
groups(6) = makeGroup("F1", "fresh_air_target_plus_5pct", solver, relTol, absTol, maxStep, 5, .5, 1.05, "air_supply");
groups(7) = makeGroup("F2", "fresh_air_target_plus_10pct", solver, relTol, absTol, maxStep, 5, .5, 1.10, "air_supply");
end

function group = makeGroup(id, label, solver, relTol, absTol, maxStep, Kp, Ki, flowFactor, factorClass)
group = groupTemplate();
group.id = string(id);
group.label = string(label);
group.factorClass = string(factorClass);
group.solver = string(solver);
group.relativeTolerance = relTol;
group.absoluteTolerance = absTol;
group.maxStep_s = maxStep;
group.Kp = Kp;
group.Ki = Ki;
group.flowFactor = flowFactor;
end

function cases = mutateCases(baseCases, group)
cases = baseCases;
for idx = 1:numel(cases)
    cases(idx).caseId = group.id + "_" + string(cases(idx).caseId);
    cases(idx).description = group.label + "; V6 diagnostic sensitivity";
    cases(idx).air.pid.Kp = group.Kp;
    cases(idx).air.pid.Ki = group.Ki;
    if group.flowFactor ~= 1
        cases(idx).air.targetMdot_kg_s = scaleMdotProfile( ...
            cases(idx).air.targetMdot_kg_s, group.flowFactor);
    end
end
end

function profile = scaleMdotProfile(profile, factor)
if isstruct(profile)
    if isfield(profile, 'start_value')
        profile.start_value = profile.start_value * factor;
    end
    if isfield(profile, 'end_value')
        profile.end_value = profile.end_value * factor;
    end
else
    profile = double(profile) * factor;
end
end

function rows = summarizeGroup(groupStudy, group, reference)
rows = repmat(rowTemplate(), numel(groupStudy.cases), 1);
for idx = 1:numel(groupStudy.cases)
    item = groupStudy.cases(idx);
    row = rowTemplate();
    row.groupId = group.id;
    row.factorClass = group.factorClass;
    row.caseId = string(getField(item, 'caseId', ""));
    row.j_A_cm2 = currentDensityFromCase(item);
    row.simCompleted = logical(getField(item, 'simCompleted', false));
    row.localNumericsPassed = logical(getField(item, 'passed', false));
    row.failureCategory = string(getField(item, 'failureCategory', ""));
    row.errorId = string(getField(item, 'errorId', ""));
    row.errorMessage = string(getField(item, 'errorMessage', ""));
    row.firstErrorTime_s = firstErrorTime(row.errorMessage);
    row.failurePath = failurePath(row.errorMessage);
    row.solver = group.solver;
    row.relativeTolerance = group.relativeTolerance;
    row.absoluteTolerance = group.absoluteTolerance;
    row.maxStep_s = group.maxStep_s;
    row.airPidKp = group.Kp;
    row.airPidKi = group.Ki;
    row.flowFactor = group.flowFactor;
    row.targetFreshAirMdot_kg_s = targetFreshAirMdot( ...
        item, reference, group.flowFactor);
    if isfield(item, 'tail') && isstruct(item.tail)
        tail = item.tail;
        row.actualFreshAirMdot_kg_s = tailMean(tail, 'freshAirApprox_kg_s');
        row.actualCompressorMdot_kg_s = tailMean(tail, 'compressorMdot_kg_s');
        row.compressorMdotSet_kg_s = tailMean(tail, 'compressorMdotSet_kg_s');
        row.compressorMdotTrackingError_kg_s = tailMean( ...
            tail, 'compressorMdotTrackingError_kg_s');
        row.compressorMdotTrackingErrorMaxAbs_kg_s = tailMaxAbs( ...
            tail, 'compressorMdotTrackingError_kg_s');
        row.compressorCommand = tailMean(tail, 'compressorCommand');
        row.compressorCommandMaximum = tailMaximum(tail, 'compressorCommand');
        row.compressorRpm = tailMean(tail, 'compressorRpm');
        row.compressorRpmMaximum = tailMaximum(tail, 'compressorRpm');
        row.oxygenMassFractionMinimum = tailMinimum(tail, 'inletO2MassFraction');
        row.lambdaMinimum = getField(item, 'lambdaTailMin', NaN);
        row.airControlError_kg_s = tailMean(tail, 'airControlError_kg_s');
        row.airControlErrorMaxAbs_kg_s = tailMaxAbs(tail, 'airControlError_kg_s');
    end
    if isfield(item, 'performance') && isstruct(item.performance) && ...
            isfield(item.performance, 'cathode')
        cathode = item.performance.cathode;
        row.oxygenPartialPressure_Pa = getField(cathode, ...
            'compressorInletO2PartialPressure_Pa', NaN);
        row.oxygenStoich = getField(cathode, 'oxygenStoich_lambda', NaN);
    end
    if isfield(item, 'saturation') && isstruct(item.saturation)
        row.saturationTailFraction = getField(item.saturation, ...
            'tailFraction', NaN);
    end
    row.rpmAtUpperLookupLimit = isfinite(row.compressorRpmMaximum) && ...
        row.compressorRpmMaximum >= 80000 - 1e-6;
    row.zeroCrossingResolved = row.simCompleted && ...
        row.localNumericsPassed && ...
        ~any(contains(lower(row.errorMessage), ...
        ["zero-crossing" "zero crossing" "consecutive zero-crossing"])) && ...
        (~isfinite(row.oxygenMassFractionMinimum) || ...
        row.oxygenMassFractionMinimum >= 0);
    rows(idx) = row;
end
end

function decision = classifyStudy(rows)
solverRows = rows(ismember([rows.groupId], ["S1" "S2"]));
controlRows = rows(ismember([rows.groupId], ["C1" "C2"]));
supplyRows = rows(ismember([rows.groupId], ["F1" "F2"]));
solverRecovered = any([solverRows.zeroCrossingResolved]);
controlRecovered = any([controlRows.zeroCrossingResolved]);
supplyRecovered = any([supplyRows.zeroCrossingResolved]);
supplyAtCapacity = any([supplyRows.rpmAtUpperLookupLimit]) || ...
    any([supplyRows.compressorCommandMaximum] >= 1 - 1e-9);

if solverRecovered && controlRecovered
    classification = "solver_and_control_sensitive";
    note = "A tighter tolerance solver and a faster PID variant both completed with the original fresh-air target and nonnegative inlet O2.";
elseif solverRecovered
    classification = "solver_sensitive";
    note = "At least one solver-only variation completed with local numerical pass and nonnegative inlet O2.";
elseif controlRecovered
    classification = "control_sensitive";
    note = "Solver variations remained unresolved while a PID-only variation completed with the original air target.";
elseif supplyRecovered
    classification = "air_supply_margin_sensitive";
    note = "Only an increased fresh-air target recovered the case; this is a model target-margin finding, not a hardware rating.";
elseif supplyAtCapacity
    classification = "air_path_capacity_boundary_candidate";
    note = "Solver/control variations remained unresolved and the supply diagnostic reached the compressor lookup/command upper envelope.";
else
    classification = "mixed_or_unresolved";
    note = "No stable solver/control/supply classification is supported by the retained observations.";
end

decision = struct( ...
    'classification', classification, ...
    'note', note, ...
    'solverRecovered', solverRecovered, ...
    'controlRecovered', controlRecovered, ...
    'supplyRecovered', supplyRecovered, ...
    'supplyAtCapacity', supplyAtCapacity, ...
    'engineeringStatus', "gas_phase_focused_boundary_only;_not_hardware_validation");
end

function row = rowTemplate()
row = struct( ...
    'groupId', "", 'factorClass', "", 'caseId', "", 'j_A_cm2', NaN, ...
    'simCompleted', false, 'localNumericsPassed', false, ...
    'failureCategory', "", 'errorId', "", 'errorMessage', "", ...
    'firstErrorTime_s', NaN, 'failurePath', "", 'solver', "", ...
    'relativeTolerance', NaN, 'absoluteTolerance', NaN, 'maxStep_s', NaN, ...
    'airPidKp', NaN, 'airPidKi', NaN, 'flowFactor', NaN, ...
    'targetFreshAirMdot_kg_s', NaN, 'actualFreshAirMdot_kg_s', NaN, ...
    'actualCompressorMdot_kg_s', NaN, 'compressorMdotSet_kg_s', NaN, ...
    'compressorMdotTrackingError_kg_s', NaN, ...
    'compressorMdotTrackingErrorMaxAbs_kg_s', NaN, ...
    'compressorCommand', NaN, 'compressorCommandMaximum', NaN, ...
    'compressorRpm', NaN, 'compressorRpmMaximum', NaN, ...
    'rpmAtUpperLookupLimit', false, 'oxygenMassFractionMinimum', NaN, ...
    'lambdaMinimum', NaN, 'oxygenPartialPressure_Pa', NaN, ...
    'oxygenStoich', NaN, 'airControlError_kg_s', NaN, ...
    'airControlErrorMaxAbs_kg_s', NaN, 'saturationTailFraction', NaN, ...
    'zeroCrossingResolved', false);
end

function value = targetFreshAirMdot(item, reference, flowFactor)
value = NaN;
if isfield(item, 'caseCfg') && isstruct(item.caseCfg) && ...
        isfield(item.caseCfg, 'air') && isstruct(item.caseCfg.air)
    profile = getField(item.caseCfg.air, 'targetMdot_kg_s', NaN);
    if isstruct(profile)
        if isfield(profile, 'end_value')
            value = double(profile.end_value);
        end
    elseif isnumeric(profile) && isscalar(profile)
        value = double(profile);
    end
end
if ~isfinite(value)
    j = currentDensityFromCase(item);
    refIndex = find(abs(reference.currentDensity_A_cm2 - j) < 1e-10, 1);
    if ~isempty(refIndex)
        value = reference.freshAirMdot_kg_s(refIndex) * flowFactor;
    end
end
end

function j = currentDensityFromCase(item)
j = NaN;
if isfield(item, 'caseCfg') && isstruct(item.caseCfg) && ...
        isfield(item.caseCfg, 'external240ReferenceCurrentDensity_A_cm2')
    j = double(item.caseCfg.external240ReferenceCurrentDensity_A_cm2);
    return;
end
token = regexp(char(string(getField(item, 'caseId', ""))), ...
    'j([0-9]+)p([0-9]+)', 'tokens', 'once');
if ~isempty(token)
    j = str2double([token{1} '.' token{2}]);
end
end

function value = tailMean(tail, name)
value = getNestedTailValue(tail, name, 'mean');
end

function value = tailMinimum(tail, name)
value = getNestedTailValue(tail, name, 'minimum');
end

function value = tailMaximum(tail, name)
value = getNestedTailValue(tail, name, 'maximum');
end

function value = tailMaxAbs(tail, name)
value = getNestedTailValue(tail, name, 'maximumAbs');
end

function value = getNestedTailValue(tail, name, stat)
value = NaN;
if isstruct(tail) && isfield(tail, name) && isstruct(tail.(name)) && ...
        isfield(tail.(name), stat)
    candidate = tail.(name).(stat);
    if isnumeric(candidate) && isscalar(candidate)
        value = double(candidate);
    end
end
end

function value = getField(s, name, default)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = default;
end
end

function time_s = firstErrorTime(message)
time_s = NaN;
text = char(message);
number = '[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?';
token = regexp(text, ['在\s*(' number ')\s*和\s*(' number ...
    ')\s*之\s*间的时间间隔'], 'tokens', 'once');
if isempty(token)
    token = regexp(text, ['(?:at\s+time|time\s*=|时间\s*=|时刻\s*=)\s*(' ...
        number ')'], 'tokens', 'once', 'ignorecase');
end
if ~isempty(token)
    time_s = str2double(token{1});
end
end

function path = failurePath(message)
text = string(message);
tokens = ["A98_FreshAirMdot_Nonnegative"; "PID Controller"; ...
    "PID"; "Saturation"; "zero-crossing"; "zero crossing"; ...
    "Mass fractions must be non-negative"];
hitMask = false(size(tokens));
for idx = 1:numel(tokens)
    hitMask(idx) = contains(lower(text), lower(tokens(idx)));
end
hits = tokens(hitMask);
path = strjoin(unique(hits, 'stable'), ' -> ');
end

function value = groupResultTemplate()
value = struct( ...
    'groupId', "", 'label', "", 'study', struct(), ...
    'rows', repmat(rowTemplate(), 0, 1), 'simCompleted', 0, ...
    'localNumericsPassed', 0, 'zeroCrossingFailureCount', 0);
end

function value = groupTemplate()
value = struct( ...
    'id', "", 'label', "", 'factorClass', "", 'solver', "", ...
    'relativeTolerance', NaN, 'absoluteTolerance', NaN, 'maxStep_s', NaN, ...
    'Kp', NaN, 'Ki', NaN, 'flowFactor', NaN);
end
