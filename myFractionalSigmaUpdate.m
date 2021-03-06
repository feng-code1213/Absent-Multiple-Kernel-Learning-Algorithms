function [Sigma,CostNew] = myFractionalSigmaUpdate(Sigma,a,S)


options.goldensearch_deltmax=1e-1; % initial precision of golden section search
options.numericalprecision=1e-16;   % numerical precision weights below this value are set to zero 
options.firstbasevariable='first'; % tie breaking method for choosing the base 
                                   % variable in the reduced gradient method
%% Sigma :current solution
[CostNew,GradNew] = myFractionalOptimization(Sigma,a,S);
%------------------------------------------------------------------------------%
% Initialize
%------------------------------------------------------------------------------%
gold = (sqrt(5)+1)/2 ;
SigmaNew  = Sigma ; 
%---------------------------------------------------------------
% Compute Current Cost and Gradient
%%--------------------------------------------------------------
GradNew = GradNew/norm(GradNew);
CostOld = CostNew;
%---------------------------------------------------------------
% Compute reduced Gradient and descent direction
%%--------------------------------------------------------------
switch options.firstbasevariable
    case 'first'
        [val,coord] = max(SigmaNew);
    case 'random'
        [val,coord] = max(SigmaNew);
        coord=find(SigmaNew==val);
        indperm=randperm(length(coord));
        coord=coord(indperm(1));
    case 'fullrandom'
        indzero=find(SigmaNew~=0);
        if ~isempty(indzero)
            [mini,coord]=min(GradNew(indzero));
            coord=indzero(coord);
        else
            [val,coord] = max(SigmaNew);
        end  
end
GradNew = GradNew - GradNew(coord);
desc = - GradNew.* ( (SigmaNew>0) | (GradNew<0) ) ;
desc(coord) = - sum(desc);  % NB:  GradNew(coord) = 0
% if norm(desc)>0
%     desc = desc/norm(desc);
% end
%----------------------------------------------------
% Compute optimal stepsize
%-----------------------------------------------------
stepmin  = 0;
costmin  = CostOld ;
costmax  = 0 ;
%-----------------------------------------------------
% maximum stepsize
%-----------------------------------------------------
ind = find(desc<0);
stepmax = min(-(SigmaNew(ind))./desc(ind));
deltmax = stepmax;
if isempty(stepmax) | stepmax==0
    Sigma = SigmaNew;
    return
end,
if stepmax > 0.1
     stepmax=0.1;
end
%-----------------------------------------------------
%  Projected gradient
%-----------------------------------------------------
while costmax<costmin
    %% Sigma :current solution
    %% [CostNew,GradNew] = myFractionalOptimization(Sigma,a,S);
    costmax = myFractionalOptimization(SigmaNew+stepmax*desc,a,S);
    if costmax<costmin
        costmin = costmax;
        SigmaNew  = SigmaNew + stepmax * desc;
 
        desc = desc .* ( (SigmaNew>options.numericalprecision) | (desc>0) ) ;
        desc(coord) = - sum(desc([[1:coord-1] [coord+1:end]]));
%         if norm(desc)>0
%             desc = desc/norm(desc);
%         end
        ind = find(desc<0);
        if ~isempty(ind)
            stepmax = min(-(SigmaNew(ind))./desc(ind));
            deltmax = stepmax;
            costmax = 0;
        else
            stepmax = 0;
            deltmax = 0;
        end       
    end
end
%-----------------------------------------------------
%  Linesearch
%-----------------------------------------------------
Step = [stepmin stepmax];
Cost = [costmin costmax];
[val,coord] = min(Cost);
% optimization of stepsize by golden search
while (stepmax-stepmin)>options.goldensearch_deltmax*(abs(deltmax))  & stepmax > eps;
    
    stepmedr = stepmin+(stepmax-stepmin)/gold;
    stepmedl = stepmin+(stepmedr-stepmin)/gold;
    
    costmedr = myFractionalOptimization(SigmaNew+stepmedr*desc,a,S);
    costmedl = myFractionalOptimization(SigmaNew+stepmedl*desc,a,S);

    Step = [stepmin stepmedl stepmedr stepmax];
    Cost = [costmin costmedl costmedr costmax];
    [val,coord] = min(Cost);
    switch coord
        case 1
            stepmax = stepmedl;
            costmax = costmedl;
        case 2
            stepmax = stepmedr;
            costmax = costmedr;
        case 3
            stepmin = stepmedl;
            costmin = costmedl;
        case 4
            stepmin = stepmedr;
            costmin = costmedr;
    end
end
%---------------------------------
% Final Updates
%---------------------------------
CostNew = Cost(coord) ;
step = Step(coord) ;
% Sigma update
if CostNew < CostOld
    SigmaNew = SigmaNew + step * desc;  
end
Sigma = SigmaNew;
Sigma(Sigma<eps)=0;
Sigma = Sigma/sum(Sigma);