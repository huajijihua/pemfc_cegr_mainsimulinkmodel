function result = routeA_focused_assess_outputs(out, model, context, caseCfg)
% Assess focused-model outputs while excluding removed anode purge gates.

result = routeA_assess_electrical_boundary_outputs( ...
    out, model, context, caseCfg);
result.cegrSplit = splitFlowMetrics(result.gasClosure);

% Anode purge is outside the focused model boundary, not a failed behavior.
result.purge = struct( ...
    'observed', false, ...
    'status', "not_applicable_focused_anode_boundary", ...
    'tailEventCount', 0);
result.tailPurgeFree = true;
result.periodicAnode.classification = "not_applicable_focused_anode_boundary";

result.localPassed = result.finiteTail && result.boundaryPassed && ...
    result.cegrPassed && result.saturationPassed && result.lambdaPassed && ...
    result.pressureDirectionPassed && result.areaPassed && ...
    result.compressorRpmLookupPassed && ...
    result.compressorMdotTrackingPassed && result.gasClosurePassed && ...
    result.steadyPassed;
result.passed = result.localPassed;
result.failureCategory = focusedFailureCategory(result);

if isfield(result.tail, 'freshAirApprox_kg_s') && ...
        result.tail.freshAirApprox_kg_s.mean > 1e-12
    result.tail.freshBasisRatio = struct( ...
        'mean', result.tail.egrMdot_kg_s.mean / ...
            result.tail.freshAirApprox_kg_s.mean, ...
        'definition', "m_cegr/m_fresh");
else
    result.tail.freshBasisRatio = struct( ...
        'mean', NaN, 'definition', "m_cegr/m_fresh");
end

result.waterObservations = routeA_focused_water_observations( ...
    out, model, context.tailWindow_s);
result.pressureObservations = routeA_focused_pressure_observations( ...
    out, model, context.tailWindow_s, ...
    caseCfg.environment.ambientPressure_MPa_abs);
result.waterBalance = focusedWaterBalance(result.gasClosure, caseCfg);
result.antiCondensation = routeA_focused_anti_condensation_analysis( ...
    result, result.pressureObservations, result.waterObservations, context);
result.performance = routeA_focused_performance_metrics(result, context);
result.membraneHumidifier = focusedMembraneHumidifierOutputs( ...
    out, context.tailWindow_s);
result.performance.membraneHumidifier = result.membraneHumidifier;
result.parameterBridge = context.focusedParameterBridge;
result.scope = "focused complete cathode and stack; fixed anode and thermal boundaries";
end

function membrane = focusedMembraneHumidifierOutputs(out, tailWindow_s)
% Read the V-MH observation contract without inventing endpoint values.

membrane = struct( ...
    'schemaVersion', "RouteA_Focused_MembraneHumidifier_v01", ...
    'status', "not_available", ...
    'architecture', "stack_outlet_to_wet_side_to_existing_split", ...
    'drySide', membraneSideTemplate("dry"), ...
    'wetSide', membraneSideTemplate("wet"), ...
    'waterTransfer', struct( ...
        'raw', seriesStatsTemplate('kg/s'), ...
        'filtered', seriesStatsTemplate('kg/s'), ...
        'direction', "not_available", ...
        'status', "not_available"), ...
    'heatTransfer', struct( ...
        'status', "not_independently_measured", ...
        'modelElement', "Membrane_Wall_Conductive_Heat_Transfer"), ...
    'pressureDrop', struct( ...
        'status', "endpoint_sensor_pending", ...
        'drySide', seriesStatsTemplate('Pa'), ...
        'wetSide', seriesStatsTemplate('Pa')), ...
    'massClosure', struct( ...
        'status', "equal_opposite_MIn_by_construction_not_independent_sensor_verified", ...
        'expectedDryPlusWetWaterSource_kg_s', 0), ...
    'energyClosure', struct( ...
        'status', "Pipe_MIn_TIn_and_conductive_wall_present_not_independently_measured"));

membrane.drySide = readMembraneSide(out, "dry", tailWindow_s);
membrane.wetSide = readMembraneSide(out, "wet", tailWindow_s);
membrane.pressureDrop.drySide = membrane.drySide.pressure;
membrane.pressureDrop.wetSide = membrane.wetSide.pressure;
membrane.waterTransfer.raw = readSeries(out, ...
    'routeA_membrane_water_transfer_raw_kg_s', tailWindow_s, 'kg/s');
membrane.waterTransfer.filtered = readSeries(out, ...
    'routeA_membrane_water_transfer_kg_s', tailWindow_s, 'kg/s');
if membrane.waterTransfer.filtered.available
    if membrane.waterTransfer.filtered.mean > 0
        membrane.waterTransfer.direction = "wet_to_dry";
    elseif membrane.waterTransfer.filtered.mean < 0
        membrane.waterTransfer.direction = "dry_to_wet";
    else
        membrane.waterTransfer.direction = "zero_net_transfer";
    end
    membrane.waterTransfer.status = ...
        "pressure_difference_conductance_with_first_order_dynamic_state";
end
if membrane.drySide.available && membrane.wetSide.available && ...
        membrane.waterTransfer.filtered.available
    membrane.status = "observed_internal_pipe_states_and_water_transfer";
end
end

function side = readMembraneSide(out, sideName, tailWindow_s)
side = membraneSideTemplate(sideName);
prefix = "routeA_membrane_" + string(sideName) + "_";
side.composition = readSeries(out, ...
    char(prefix + "composition_mole_fraction"), tailWindow_s, '1');
side.pressure = readSeries(out, ...
    char(prefix + "pressure_Pa"), tailWindow_s, 'Pa');
side.temperature = readSeries(out, ...
    char(prefix + "temperature_K"), tailWindow_s, 'K');
side.h2oPartialPressure = readSeries(out, ...
    char(prefix + "h2o_partial_pressure_Pa"), tailWindow_s, 'Pa');
side.available = side.composition.available || side.pressure.available || ...
    side.temperature.available || side.h2oPartialPressure.available;
if side.available
    side.status = "pipe_volume_state_observed";
end
end

function side = membraneSideTemplate(name)
side = struct( ...
    'name', string(name), ...
    'available', false, ...
    'status', "not_available", ...
    'composition', seriesStatsTemplate('1'), ...
    'pressure', seriesStatsTemplate('Pa'), ...
    'temperature', seriesStatsTemplate('K'), ...
    'h2oPartialPressure', seriesStatsTemplate('Pa'));
end

function stats = readSeries(out, name, tailWindow_s, unit)
stats = seriesStatsTemplate(unit);
if ~hasSimulationOutput(out, name)
    return;
end
value = out.(name);
[time, data, ok] = decodeWorkspaceOutput(value);
if ~ok || isempty(time) || isempty(data)
    return;
end
data = reshapeTimeData(data, numel(time));
window = time >= tailWindow_s(1) & time <= tailWindow_s(2);
if ~any(window)
    window = true(size(time));
end
values = data(:, window);
stats.available = true;
stats.unit = string(unit);
stats.timeStart_s = time(find(window, 1, 'first'));
stats.timeEnd_s = time(find(window, 1, 'last'));
stats.first = data(:, find(window, 1, 'first'));
stats.last = data(:, find(window, 1, 'last'));
stats.mean = mean(values, 2, 'omitnan');
stats.min = min(values, [], 2, 'omitnan');
stats.max = max(values, [], 2, 'omitnan');
end

function stats = seriesStatsTemplate(unit)
stats = struct( ...
    'available', false, ...
    'unit', string(unit), ...
    'timeStart_s', NaN, ...
    'timeEnd_s', NaN, ...
    'first', NaN, ...
    'last', NaN, ...
    'mean', NaN, ...
    'min', NaN, ...
    'max', NaN);
end

function present = hasSimulationOutput(out, name)
present = false;
try
    present = any(strcmp(out.who, name));
catch
end
end

function [time, data, ok] = decodeWorkspaceOutput(value)
time = [];
data = [];
ok = false;
if isa(value, 'timeseries')
    time = value.Time(:);
    data = value.Data;
    ok = true;
elseif isstruct(value) && isfield(value, 'time') && ...
        isfield(value, 'signals') && isfield(value.signals, 'values')
    time = value.time(:);
    data = value.signals.values;
    ok = true;
end
end

function data = reshapeTimeData(data, timeCount)
if isvector(data) && numel(data) == timeCount
    data = reshape(data, 1, timeCount);
    return;
end
dimensions = size(data);
timeDimension = find(dimensions == timeCount, 1, 'last');
if isempty(timeDimension)
    data = reshape(data, [], timeCount);
    return;
end
order = [setdiff(1:ndims(data), timeDimension, 'stable'), timeDimension];
data = permute(data, order);
data = reshape(data, [], timeCount);
end

function balance = focusedWaterBalance(gasClosure, caseCfg)
% Keep direct vapor flows separate from Faraday-derived MEA water.

balance = struct( ...
    'schemaVersion', "RouteA_Focused_WaterBalance_v01", ...
    'externalWaterInjectionEnableCommand', NaN, ...
    'meaWaterGenerationFaraday_kg_s', NaN, ...
    'recycleWaterVaporMdot_kg_s', NaN, ...
    'outletWaterVaporMdot_kg_s', NaN, ...
    'mixWaterResidual_kg_s', NaN, ...
    'meaWaterStatus', "not_available", ...
    'recycleWaterVaporStatus', "not_available", ...
    'liquidWaterStatus', "not_implemented_L2_gas_phase_only");

if isfield(caseCfg, 'cathode') && isstruct(caseCfg.cathode) && ...
        isfield(caseCfg.cathode, 'humidifierEnabled')
    balance.externalWaterInjectionEnableCommand = ...
        double(caseCfg.cathode.humidifierEnabled);
end

if ~isstruct(gasClosure)
    return;
end

if isfield(gasClosure, 'o2FaradayConsumption_kg_s') && ...
        isfinite(gasClosure.o2FaradayConsumption_kg_s)
    % 2 H2O are produced for every O2 consumed by the cathode reaction.
    balance.meaWaterGenerationFaraday_kg_s = ...
        1.125 * gasClosure.o2FaradayConsumption_kg_s;
    balance.meaWaterStatus = "derived_from_o2_faraday_consumption";
end

if isfield(gasClosure, 'recycleSpeciesMdot_kg_s') && ...
        numel(gasClosure.recycleSpeciesMdot_kg_s) >= 4
    balance.recycleWaterVaporMdot_kg_s = ...
        gasClosure.recycleSpeciesMdot_kg_s(4);
    balance.recycleWaterVaporStatus = ...
        "measured_post_split_return_branch_gas_phase";
end

if isfield(gasClosure, 'outletSpeciesMdot_kg_s') && ...
        numel(gasClosure.outletSpeciesMdot_kg_s) >= 4
    balance.outletWaterVaporMdot_kg_s = ...
        gasClosure.outletSpeciesMdot_kg_s(4);
end
if isfield(gasClosure, 'h2oMixResidual_kg_s')
    balance.mixWaterResidual_kg_s = gasClosure.h2oMixResidual_kg_s;
end
end

function category = focusedFailureCategory(result)
reasons = strings(1, 0);
if ~result.boundaryPassed
    reasons(end + 1) = "electrical_boundary";
end
if ~result.cegrPassed
    reasons(end + 1) = "cegr_tracking";
end
if ~result.saturationPassed
    reasons(end + 1) = "current_saturation";
end
if ~result.lambdaPassed
    reasons(end + 1) = "oxygen_supply";
end
if ~result.gasClosurePassed
    reasons(end + 1) = "gas_closure";
end
if ~result.pressureDirectionPassed
    reasons(end + 1) = "pressure_direction";
end
if ~result.areaPassed
    reasons(end + 1) = "valve_area";
end
if ~result.compressorRpmLookupPassed
    reasons(end + 1) = "compressor_rpm";
end
if ~result.compressorMdotTrackingPassed
    reasons(end + 1) = "compressor_mdot_tracking";
end
if ~result.steadyPassed
    reasons(end + 1) = "not_steady";
end
category = strjoin(reasons, ";");
end

function split = splitFlowMetrics(gasClosure)
split = struct( ...
    'returnMdot_kg_s', NaN, ...
    'exhaustMdot_kg_s', NaN, ...
    'totalMdot_kg_s', NaN, ...
    'ratioTotalMassBasis', NaN, ...
    'ratioDryBasis', NaN, ...
    'basis', "current_return_plus_exhaust_branch_total_mass_flow", ...
    'dryBasisStatus', "not_available_branch_species", ...
    'status', "current_branch_flow_ideal_tee_gas_phase_proxy_not_liquid_validation");

if ~isstruct(gasClosure) || ...
        ~isfield(gasClosure, 'recycleMdot_kg_s') || ...
        ~isfield(gasClosure, 'exhaustMdot_kg_s')
    return;
end

returnMdot = double(gasClosure.recycleMdot_kg_s);
exhaustMdot = double(gasClosure.exhaustMdot_kg_s);
if ~isscalar(returnMdot) || ~isscalar(exhaustMdot) || ...
        ~isfinite(returnMdot) || ~isfinite(exhaustMdot)
    return;
end

totalMdot = returnMdot + exhaustMdot;
split.returnMdot_kg_s = returnMdot;
split.exhaustMdot_kg_s = exhaustMdot;
split.totalMdot_kg_s = totalMdot;
split.basis = "current_return_plus_exhaust_branch_total_mass_flow";
if totalMdot > 1e-12 && returnMdot >= 0 && exhaustMdot >= 0
    split.ratioTotalMassBasis = returnMdot / totalMdot;
    split.status = "current_branch_flow_ideal_tee_gas_phase_proxy_not_liquid_validation";
end
end
