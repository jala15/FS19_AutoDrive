function AutoDrive:handleTrailers(vehicle, dt)
    if vehicle.ad.isActive == true and vehicle.ad.unloadAtTrigger == true and vehicle.isServer == true then
        local trailers, trailerCount = AutoDrive:getTrailersOf(vehicle);        			
		--print("Autodrive detected trailers: " .. trailerCount);			

        if trailerCount == 0 then
            return
        end;
        
        
        local leftCapacity = 0;
        for _,trailer in pairs(trailers) do
            for _,fillUnit in pairs(trailer:getFillUnits()) do
                leftCapacity = leftCapacity + trailer:getFillUnitFreeCapacity(_)
            end
        end;

        --check distance to unloading destination, do not unload too far from it. You never know where the tractor might already drive over an unloading trigger before that
        local x,y,z = getWorldTranslation(vehicle.components[1].node);
        local destination = AutoDrive.mapWayPoints[vehicle.ad.targetSelected_Unload];
        local distance = getDistance(x,z, destination.x, destination.z);
        if distance < 20 then
            for _,trailer in pairs(trailers) do
                for _,trigger in pairs(AutoDrive.Triggers.tipTriggers) do

                    local currentDischargeNode = trailer:getCurrentDischargeNode()
                    local distanceToTrigger, bestTipReferencePoint = 0, currentDischargeNode;

                    --find the best TipPoint
                    if not trailer:getCanDischargeToObject(currentDischargeNode) then
                        for i=1,#trailer.spec_dischargeable.dischargeNodes do
                            if trailer:getCanDischargeToObject(trailer.spec_dischargeable.dischargeNodes[i])then
                                trailer:setCurrentDischargeNodeIndex(trailer.spec_dischargeable.dischargeNodes[i]);
                                currentDischargeNode = trailer:getCurrentDischargeNode()
                                break
                            end
                        end
                    end
                    
                    if trailer:getCanDischargeToObject(currentDischargeNode) then
                        --print("Current discharge node possible");
                        trailer:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
                        vehicle.ad.isPaused = true;
                        vehicle.ad.isUnloading = true;
                    end;
                    
                    local dischargeState = trailer:getDischargeState()
                    if dischargeState == Trailer.TIPSTATE_CLOSED or dischargeState == Trailer.TIPSTATE_CLOSING then
                        vehicle.ad.isPaused = false;
                        vehicle.ad.isUnloading = false;
                        --print("Trailer is empty - continue");
                    end;
                end;
            end;
        end;

        if leftCapacity == 0 and vehicle.ad.isPaused then
            vehicle.ad.isPaused = false;
            vehicle.ad.isUnloading = false;
            vehicle.ad.isLoading = false;
        end;
    end;
end;

function AutoDrive:getTrailersOf(vehicle)
    local trailers = {};
    local trailerCount = 0;
    local trailer = nil;
    if vehicle.getAttachedImplements ~= nil then
        local hasImplements = true;
        local toCheck = vehicle
        while hasImplements do
            hasImplements = false;
            if toCheck.getAttachedImplements ~= nil then
                for _, implement in pairs(toCheck:getAttachedImplements()) do                    
                    if implement.object ~= nil then
                        --if workTool.spec_dischargeable and workTool.cp.capacity and workTool.cp.capacity > 0.1 then
                        if implement.object.typeDesc == g_i18n:getText("typeDesc_tipper") then
                            trailer = implement.object;
                            trailerCount = 1;
                            trailers[trailerCount] = trailer;
                            toCheck = implement;
                            hasImplements = true;
                        end;
                    end;
                end;
            end;
        end;
    end;

    return trailers, trailerCount;
end;

function AutoDrive:getCurrentFillType(vehicle)
    local trailer = nil;
    if vehicle.attachedImplements ~= nil then
        for _, implement in pairs(vehicle.attachedImplements) do
            if implement.object ~= nil then
                if implement.object.typeDesc == g_i18n:getText("typeDesc_tipper") then
                    trailer = implement.object;
                end;
            end;
        end;
    end;

    if vehicle.bUnloadAtTrigger == true and trailer ~= nil then
        local fillTable = trailer:getCurrentFillTypes();
        if fillTable[1] ~= nil then
            return fillTable[1];
        end;
    end;
end;