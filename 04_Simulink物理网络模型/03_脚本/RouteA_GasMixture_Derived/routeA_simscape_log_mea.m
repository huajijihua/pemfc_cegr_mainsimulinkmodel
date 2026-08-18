function mea = routeA_simscape_log_mea(simlog)
% Return the MEA Simscape log node for the current Route A hierarchy.

stackCandidates = ["PEMFC_Stack_Core", "Stack_Core"];
meaCandidates = ["MEA_FC", "Membrane_Electrode_Assembly"];
for stackName = stackCandidates
    if ~isprop(simlog, stackName)
        continue;
    end
    stackNode = simlog.(stackName);
    for meaName = meaCandidates
        if isprop(stackNode, meaName)
            mea = stackNode.(meaName);
            return;
        end
    end
end
if isprop(simlog, 'Membrane_Electrode_Assembly')
    mea = simlog.Membrane_Electrode_Assembly;
    return;
end
error('RouteA:MissingMEAInSimscapeLog', ...
    'Membrane Electrode Assembly was not found in the Simscape log.');
end
