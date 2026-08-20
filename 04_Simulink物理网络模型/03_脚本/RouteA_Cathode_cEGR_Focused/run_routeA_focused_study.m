function study = run_routeA_focused_study(studyCfg)
% Run focused cathode-cEGR cases through the formal serial/parallel runner.
%
% The runner reuses the shared Route A input adapter and cathode/electrical
% output assessor, while the model boundary owns the fixed anode and thermal
% interfaces. Current, Power, and Voltage cases are run as separate calls.
% Parallel execution uses parsim only after all SimulationInput objects have
% been prepared on the client; result assessment remains deterministic here.

if nargin < 1 || isempty(studyCfg)
    error('RouteA:FocusedStudyConfig', ...
        'A nonempty study configuration is required.');
end

requestedModelId = "focused_legacy";
if isfield(studyCfg, 'modelId') && ...
        strlength(string(studyCfg.modelId)) > 0
    requestedModelId = lower(string(studyCfg.modelId));
end
paths = routeA_focused_paths(requestedModelId);
addpath(char(paths.sharedScriptDir));
model = char(paths.modelName);
modelDir = char(paths.modelDir);
if ~bdIsLoaded(model)
    load_system(char(paths.modelFile));
end

defaults = routeA_focused_parameter_defaults(requestedModelId);
cfg = normalizeConfig(studyCfg, defaults);
if cfg.modelId ~= requestedModelId
    error('RouteA:FocusedModelStudy', ...
        'The study modelId must match the selected focused model.');
end
caseCount = numel(cfg.cases);
results = cell(caseCount, 1);
outputs = cell(caseCount, 1);
preparedInputs = cell(caseCount, 1);
preparedContexts = cell(caseCount, 1);
preparedCases = cell(caseCount, 1);
preparedAdapters = cell(caseCount, 1);
preparedBridges = cell(caseCount, 1);
execution = struct( ...
    'requestedCaseIds', strings(0, 1), ...
    'preparedCaseIds', strings(0, 1), ...
    'executedCaseIds', strings(0, 1), ...
    'completedCaseIds', strings(0, 1), ...
    'failedCaseIds', strings(0, 1), ...
    'executionMode', cfg.executionMode, ...
    'parallel', parallelExecutionTemplate(cfg), ...
    'halted', false, ...
    'haltReason', "");

for idx = 1:caseCount
    rawCaseCfg = cfg.cases(idx);
    caseCfg = rawCaseCfg;
    caseId = string(caseCfg.caseId);
    execution.requestedCaseIds(end + 1, 1) = caseId;
    result = failureTemplate();
    result.caseId = caseId;
    try
        [caseCfg, caseAdapter] = routeA_focused_case_adapter( ...
            rawCaseCfg, defaults);
        caseId = string(caseCfg.caseId);
        adapterCfg = rmfield(cfg, ...
            {'retainSimulationOutputs', 'resultFile', 'cases', 'boundaryType', ...
            'architectureId', 'modelId', 'externalCalibrationReference', ...
            'hydraulicScreenContract', 'cegrScreenContract', 'executionMode', ...
            'parallel'});
        [in, context] = routeA_prepare_electrical_boundary_input( ...
            model, modelDir, caseCfg, adapterCfg);
        [in, focusedBridge] = applyFocusedVariables( ...
            in, caseCfg, defaults, model);
        context.focusedCaseAdapter = caseAdapter;
        context.focusedParameterBridge = focusedBridge;
        preparedInputs{idx} = in;
        preparedContexts{idx} = context;
        preparedCases{idx} = caseCfg;
        preparedAdapters{idx} = caseAdapter;
        preparedBridges{idx} = focusedBridge;
        execution.preparedCaseIds(end + 1, 1) = caseId;
    catch exception
        result.errorId = string(exception.identifier);
        result.errorMessage = string(getReport(exception, 'extended', ...
            'hyperlinks', 'off'));
        result.failureCategory = classifyFocusedFailure(result.errorMessage);
        execution.failedCaseIds(end + 1, 1) = caseId;
    end
    results{idx} = harmonizeResult(result);
end

preflight = routeA_focused_preflight(model, paths, defaults, cfg, ...
    preparedInputs, preparedBridges);
if ~preflight.passed
    error('RouteA:FocusedPreflight', ...
        'Focused runner preflight failed: %s.', ...
        strjoin(preflight.failureReasons, '; '));
end

runnableIdx = find(~cellfun(@isempty, preparedInputs));
simulationOutputs = cell(caseCount, 1);
if ~isempty(runnableIdx)
    try
        [simulationOutputs, execution] = runPreparedCases( ...
            preparedInputs, runnableIdx, cfg, execution);
    catch exception
        for idx = runnableIdx(:).'
            result = failureTemplate();
            result.caseId = string(preparedCases{idx}.caseId);
            result.errorId = string(exception.identifier);
            result.errorMessage = string(getReport(exception, 'extended', ...
                'hyperlinks', 'off'));
            result.failureCategory = classifyFocusedFailure(result.errorMessage);
            results{idx} = harmonizeResult(result);
            execution.failedCaseIds(end + 1, 1) = result.caseId;
        end
        runnableIdx = [];
    end
end

for idx = runnableIdx(:).'
    caseCfg = preparedCases{idx};
    caseId = string(caseCfg.caseId);
    result = failureTemplate();
    result.caseId = caseId;
    try
        out = simulationOutputs{idx};
        if strlength(string(out.ErrorMessage)) > 0
            error('RouteA:FocusedSimulationError', '%s', out.ErrorMessage);
        end
        result = routeA_focused_assess_outputs( ...
            out, model, preparedContexts{idx}, caseCfg);
        result.caseCfg = caseCfg;
        result.caseAdapter = preparedAdapters{idx};
        result.parameterBridge = preparedBridges{idx};
        result.simCompleted = true;
        execution.completedCaseIds(end + 1, 1) = caseId;
        if cfg.retainSimulationOutputs
            outputs{idx} = out;
        end
    catch exception
        result.errorId = string(exception.identifier);
        result.errorMessage = string(getReport(exception, 'extended', ...
            'hyperlinks', 'off'));
        result.failureCategory = classifyFocusedFailure(result.errorMessage);
        execution.failedCaseIds(end + 1, 1) = caseId;
    end
    results{idx} = harmonizeResult(result);
end

results = packResults(results);
execution.matrixComplete = numel(execution.completedCaseIds) == caseCount;
if ~execution.matrixComplete
    execution.halted = true;
    execution.haltReason = "one_or_more_cases_failed";
end
[architectureId, architecture] = studyArchitecture(cfg, defaults);

study = struct();
study.schemaVersion = "RouteA_Focused_Study_v03";
study.timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
study.modelId = cfg.modelId;
study.model = string(model);
study.modelFile = paths.modelFile;
study.sourceModel = paths.sourceModelName;
study.parameterLayer = defaults.parameterLayer;
study.architectureId = architectureId;
study.targetArchitectureId = defaults.targetArchitectureId;
study.architecture = architecture;
study.initializationPolicy = "cold_start_only";
study.boundaryType = cfg.boundaryType;
study.researchDuration_s = cfg.researchDuration_s;
study.tailLogicalWindow_s = cfg.tailLogicalWindow_s;
study.parameterInterface = defaults.interface;
study.preflight = preflight;
study.solver = struct( ...
    'name', cfg.solver, ...
    'relativeTolerance', cfg.relativeTolerance, ...
    'absoluteTolerance', cfg.absoluteTolerance, ...
    'maxStep_s', cfg.studyMaxStep_s);
study.cases = results;
study.execution = execution;
study.passed = execution.matrixComplete && ...
    all([results.passed]);
study.retainSimulationOutputs = cfg.retainSimulationOutputs;
if cfg.retainSimulationOutputs
    study.outputs = outputs;
else
study.outputs = {};
end

study.performance = routeA_focused_performance_analysis(study);
study.external240Calibration = struct();
if isstruct(cfg.externalCalibrationReference) && ...
        ~isempty(fieldnames(cfg.externalCalibrationReference))
    study.external240Calibration = ...
        routeA_focused_external240kw_calibration_assessment( ...
        study, cfg.externalCalibrationReference);
end
study.hydraulicScreen = struct();
if isstruct(cfg.hydraulicScreenContract) && ...
        ~isempty(fieldnames(cfg.hydraulicScreenContract))
    study.hydraulicScreen = routeA_focused_hydraulic_screen_assessment( ...
        study, cfg.hydraulicScreenContract);
end
study.cegrScreenAudit = struct();
if isstruct(cfg.cegrScreenContract) && ...
        ~isempty(fieldnames(cfg.cegrScreenContract))
    study.cegrScreenAudit = routeA_focused_cegr_screen_assessment( ...
        study, cfg.cegrScreenContract);
end

if strlength(cfg.resultFile) > 0
    routeA_focused_study = study;
    save(char(cfg.resultFile), 'routeA_focused_study', '-v7.3');
    study.resultFile = cfg.resultFile;
else
    study.resultFile = "";
end
assignin('base', 'routeA_focused_study', study);
end

function cfg = normalizeConfig(user, defaults)
cfg = struct( ...
    'calculationType', "steady", ...
    'researchDuration_s', defaults.solver.stopTime_s, ...
    'tailLogicalWindow_s', [defaults.solver.stopTime_s - 60, defaults.solver.stopTime_s], ...
    'steadyWindowDuration_s', 60, ...
    'steadyRelativeVariationLimit', 0.005, ...
    'engineeringSteadyRelativeVariationLimit', 0.01, ...
    'solver', defaults.solver.solver, ...
    'relativeTolerance', defaults.solver.relTol, ...
    'absoluteTolerance', defaults.solver.absTol, ...
    'studyMaxStep_s', defaults.solver.maxStep_s, ...
    'commandStartOffset_s', 0.5, ...
    'startupRampDuration_s', 60, ...
    'retainSimulationOutputs', false, ...
    'executionMode', "serial", ...
    'parallel', struct( ...
        'poolProfile', "local", ...
        'workerCount', 4, ...
        'showProgress', true, ...
        'useFastRestart', false), ...
    'resultFile', "", ...
    'externalCalibrationReference', struct(), ...
    'hydraulicScreenContract', struct(), ...
    'cegrScreenContract', struct(), ...
    'cases', struct([]), ...
    'architectureId', "", ...
    'modelId', defaults.modelId);

names = fieldnames(user);
for idx = 1:numel(names)
    if ~isfield(cfg, names{idx})
        error('RouteA:FocusedStudyField', ...
            'Unsupported focused study field: %s.', names{idx});
    end
    cfg.(names{idx}) = user.(names{idx});
end

if isempty(cfg.cases) || ~isstruct(cfg.cases)
    error('RouteA:FocusedCases', 'studyCfg.cases must be a nonempty struct array.');
end
types = strings(1, numel(cfg.cases));
for idx = 1:numel(cfg.cases)
    if ~isfield(cfg.cases(idx), 'caseId') || ...
            strlength(string(cfg.cases(idx).caseId)) == 0
        cfg.cases(idx).caseId = "focused_case_" + idx;
    end
    if isfield(cfg.cases(idx), 'boundary') && ...
            isstruct(cfg.cases(idx).boundary) && ...
            isfield(cfg.cases(idx).boundary, 'type')
        types(idx) = string(cfg.cases(idx).boundary.type);
    elseif isfield(cfg.cases(idx), 'controls') && ...
            isstruct(cfg.cases(idx).controls) && ...
            isfield(cfg.cases(idx).controls, 'electrical') && ...
            isfield(cfg.cases(idx).controls.electrical, 'mode')
        types(idx) = string(cfg.cases(idx).controls.electrical.mode);
    else
        error('RouteA:FocusedBoundary', ...
            'Each focused case must define boundary.type or controls.electrical.mode.');
    end
end
types = unique(types, 'stable');
if numel(types) ~= 1 || ~any(types == ["Current", "Power", "Voltage"])
    error('RouteA:FocusedBoundaryType', ...
        'A focused study call must contain one Current, Power, or Voltage boundary type.');
end
cfg.boundaryType = types(1);
architectureIds = strings(1, numel(cfg.cases));
for idx = 1:numel(cfg.cases)
    if isfield(cfg.cases(idx), 'architecture') && ...
            isstruct(cfg.cases(idx).architecture) && ...
            isfield(cfg.cases(idx).architecture, 'id') && ...
            strlength(string(cfg.cases(idx).architecture.id)) > 0
        architectureIds(idx) = string(cfg.cases(idx).architecture.id);
    else
        architectureIds(idx) = string(defaults.architectureId);
    end
end
architectureIds = unique(architectureIds, 'stable');
if numel(architectureIds) ~= 1
    error('RouteA:FocusedArchitectureStudy', ...
        'A focused study call must contain exactly one architecture id.');
end
cfg.architectureId = architectureIds(1);
cfg.modelId = lower(string(cfg.modelId));
cfg.calculationType = lower(string(cfg.calculationType));
cfg.solver = string(cfg.solver);
cfg.executionMode = lower(string(cfg.executionMode));
if ~any(cfg.executionMode == ["serial", "parallel"])
    error('RouteA:FocusedExecutionMode', ...
        'executionMode must be serial or parallel.');
end
if ~isstruct(cfg.parallel) || ~isscalar(cfg.parallel)
    error('RouteA:FocusedParallelConfig', ...
        'parallel must be a scalar configuration struct.');
end
requiredParallelFields = {'poolProfile', 'workerCount', 'showProgress', ...
    'useFastRestart'};
if ~all(isfield(cfg.parallel, requiredParallelFields))
    error('RouteA:FocusedParallelConfig', ...
        'parallel must define poolProfile, workerCount, showProgress, and useFastRestart.');
end
cfg.parallel.poolProfile = string(cfg.parallel.poolProfile);
validateattributes(cfg.parallel.workerCount, {'numeric'}, ...
    {'scalar', 'integer', 'positive'}, mfilename, 'parallel.workerCount');
cfg.parallel.showProgress = logical(cfg.parallel.showProgress);
cfg.parallel.useFastRestart = logical(cfg.parallel.useFastRestart);
cfg.tailLogicalWindow_s = cfg.tailLogicalWindow_s(:).';
cfg.resultFile = string(cfg.resultFile);
end

function [outputs, execution] = runPreparedCases(inputs, runnableIdx, cfg, execution)
outputs = cell(numel(inputs), 1);
caseIds = execution.preparedCaseIds;
if cfg.executionMode == "serial"
    for runIdx = 1:numel(runnableIdx)
        idx = runnableIdx(runIdx);
        outputs{idx} = sim(inputs{idx});
        execution.executedCaseIds(end + 1, 1) = caseIds(runIdx);
    end
    return;
end

pool = gcp('nocreate');
if isempty(pool)
    pool = parpool(char(cfg.parallel.poolProfile), cfg.parallel.workerCount);
    execution.parallel.poolProfileStatus = "created_requested_pool";
elseif ~strcmp(pool.Cluster.Profile, char(cfg.parallel.poolProfile))
    % An already running pool is a normal MATLAB session resource. Use it
    % deterministically and record the deviation without emitting a warning.
    execution.parallel.poolProfileStatus = "used_existing_pool";
else
    execution.parallel.poolProfileStatus = "used_matching_existing_pool";
end
execution.parallel.poolProfileUsed = string(pool.Cluster.Profile);
execution.parallel.workerCountUsed = pool.NumWorkers;

simInputs = vertcat(inputs{runnableIdx});
parallelOutputs = parsim(simInputs, ...
    'ShowProgress', onOff(cfg.parallel.showProgress), ...
    'UseFastRestart', onOff(cfg.parallel.useFastRestart), ...
    'ManageDependencies', 'on', ...
    'StopOnError', 'off');
for runIdx = 1:numel(runnableIdx)
    idx = runnableIdx(runIdx);
    outputs{idx} = parallelOutputs(runIdx);
    execution.executedCaseIds(end + 1, 1) = caseIds(runIdx);
end
end

function value = parallelExecutionTemplate(cfg)
value = struct( ...
    'requested', cfg.executionMode == "parallel", ...
    'poolProfileRequested', string(cfg.parallel.poolProfile), ...
    'workerCountRequested', cfg.parallel.workerCount, ...
    'poolProfileUsed', "", ...
    'workerCountUsed', NaN, ...
    'poolProfileStatus', "not_started", ...
    'useFastRestart', cfg.parallel.useFastRestart);
end

function value = onOff(flag)
if flag
    value = 'on';
else
    value = 'off';
end
end

function [in, bridge] = applyFocusedVariables(in, caseCfg, defaults, model)
[focused, bridge] = routeA_focused_parameter_bridge(caseCfg, defaults);
values = { ...
    'focused_stack_temperature_C', focused.stackTemperature_C; ...
    'focused_cathode_inlet_temperature_C', focused.cathodeGasTemperature_C; ...
    'stack_io', focused.stackIo_A_cm2; ...
    'stack_alpha', focused.stackAlpha; ...
    'env_p', focused.cathodeSourcePressure_MPa_abs; ...
    'env_T', focused.cathodeSourceTemperature_C; ...
    'cegr_inlet_mixer_p0', focused.cathodeSourcePressure_MPa_abs; ...
    'cathode_channel_dp_nominal_MPa', ...
        focused.cathodeChannelDpNominal_MPa; ...
    'cathode_channel_mdot_nominal_kg_s', ...
        focused.cathodeChannelMdotNominal_kg_s; ...
    'cathode_channel_flow_area_m2', focused.cathodeChannelFlowArea_m2; ...
    'cathode_channel_laminar_fraction', ...
        focused.cathodeChannelLaminarFraction; ...
    'exhaust_bp_valve_max_area', ...
        focused.exhaustBackpressureValveMaxArea_m2; ...
    'exhaust_bp_valve_open_min_area', ...
        focused.exhaustBackpressureValveOpenMinArea_m2; ...
    'exhaust_bp_valve_control_Ki_area_per_MPa_s', ...
        focused.exhaustBackpressureValveKi_area_per_MPa_s; ...
    'focused_anode_feed_p_MPa_abs', focused.anodeFeedPressure_MPa_abs; ...
    'focused_anode_inlet_mdot_kg_s', focused.anodeInletMdot_kg_s; ...
    'focused_anode_outlet_p_MPa_abs', focused.anodeOutletPressure_MPa_abs; ...
    'focused_anode_boundary_T_C', focused.anodeBoundaryTemperature_C; ...
    'focused_anode_yH2', focused.anodeHydrogenMoleFraction; ...
    'focused_anode_pipe_length', focused.anodePipeLength_m; ...
    'focused_anode_pipe_area', focused.anodePipeArea_m2; ...
    'focused_anode_pipe_extra_length', focused.anodePipeExtraLength_m; ...
    'focused_anode_pipe_roughness', focused.anodePipeRoughness_m};
if lower(string(defaults.modelId)) == "ejector_self_humidifying"
    values = [values; { ...
    'ejector_enabled', focused.ejectorEnabled; ...
    'ejector_area_throat_m2', focused.ejectorAreaThroat_m2; ...
    'ejector_area_ratio_nozzle', focused.ejectorAreaRatioNozzle; ...
    'ejector_area_ratio_mixing', focused.ejectorAreaRatioMixing; ...
    'ejector_min_area_ratio_secondary', focused.ejectorMinAreaRatioSecondary; ...
    'ejector_efficiency_primary', focused.ejectorEfficiencyPrimary; ...
    'ejector_efficiency_secondary', focused.ejectorEfficiencySecondary; ...
    'ejector_efficiency_expansion', focused.ejectorEfficiencyExpansion; ...
    'ejector_efficiency_mixing', focused.ejectorEfficiencyMixing; ...
    'ejector_area_A_m2', focused.ejectorAreaA_m2; ...
    'ejector_area_B_m2', focused.ejectorAreaB_m2; ...
    'ejector_area_S_m2', focused.ejectorAreaS_m2; ...
    'ejector_pressure_recovery', focused.ejectorPressureRecovery; ...
    'ejector_pressure_smoothing_Pa', focused.ejectorPressureSmoothing_Pa; ...
    'ejector_mdot_smoothing_kg_s', focused.ejectorMdotSmoothing_kg_s}];
end
for idx = 1:size(values, 1)
    in = in.setVariable(values{idx, 1}, values{idx, 2}, ...
        'Workspace', model);
end
end

function result = failureTemplate()
result = struct( ...
    'caseId', "", ...
    'simCompleted', false, ...
    'passed', false, ...
    'failureCategory', "not_run", ...
    'errorId', "", ...
    'errorMessage', "");
end

function category = classifyFocusedFailure(message)
text = lower(string(message));
if contains(text, "mass fractions must be non-negative") || ...
        contains(text, "mass fraction") && contains(text, "non-negative")
    category = "oxygen_supply_mass_fraction_nonnegative";
elseif contains(text, "连续过零") || ...
        contains(text, "consecutive zero-crossing")
    category = "zero_crossing_chatter";
elseif contains(text, "assertion")
    category = "simulation_assertion";
else
    category = "simulation_or_collection_error";
end
end

function result = harmonizeResult(value)
result = failureTemplate();
names = fieldnames(value);
for idx = 1:numel(names)
    result.(names{idx}) = value.(names{idx});
end
end

function results = packResults(cells)
fields = {};
for idx = 1:numel(cells)
    fields = union(fields, fieldnames(cells{idx}), 'stable');
end
results = repmat(struct(), numel(cells), 1);
for idx = 1:numel(cells)
    for fieldIdx = 1:numel(fields)
        name = fields{fieldIdx};
        if isfield(cells{idx}, name)
            results(idx).(name) = cells{idx}.(name);
        else
            results(idx).(name) = [];
        end
    end
end
end

function [architectureId, architecture] = studyArchitecture(cfg, defaults)
architectureId = cfg.architectureId;
architecture = defaults.architecture;
for idx = 1:numel(cfg.cases)
    if isfield(cfg.cases(idx), 'architecture') && ...
            isstruct(cfg.cases(idx).architecture)
        architecture = cfg.cases(idx).architecture;
        break;
    end
end
architecture.id = architectureId;
end
