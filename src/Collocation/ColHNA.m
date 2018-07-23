function [v_N, GOA, colMatrix, colRHS] = ColHNA(Operator, Vbasis, uinc, Gamma, varargin)
%computes oversampled collocation projection using HNA basis/frame

    %with RHS data
    f=DirichletData(uinc,Gamma);
    %construct Geometrical optics approximation on Gamma
    GOA=GeometricalOpticsApprox(uinc,Gamma);
    
    DOFs=length(Vbasis.el);
    
    % -----------------------
    %defaults:
    Nquad = 20;
    scaler=1;
    colType='C';
    overSamplesPerMeshEl=1;
    messageFlag=false;
    standardBEMflag = false;
    standardQuadFlag = false;
    % -----------------------
    
    for j=1:length(varargin)
        if ischar(varargin{j})
           lowerCaseArg=lower(varargin{j});
           switch lowerCaseArg
               case 'oversample'
                   overSamplesPerMeshEl=varargin{j+1};
               case 'coltype'
                   colType=varargin{j+1};
               case 'quadpoints'
                   Nquad=varargin{j+1};
               case 'max stationary point order'
                   maxSPorder=varargin{j+1};
               case 'progress'
                   messageFlag = true;
               case 'cg'
                   standardQuadFlag = true;
           end
        end
    end
    
    if isa(Vbasis,'hpStandardBasis')
       standardBEMflag = true;
    end
    
    %start timer, if user is interested
    if messageFlag
        tic;
    end
    
    %get collocation points.
    [X, Xside, Xdist2a, Xdist2b, Xstruct] = getColPoints( Vbasis, overSamplesPerMeshEl, scaler, colType);
    
    %** should eventually find a way to partition the basis into mesh
    %elements with + or - phase, so that quadrature points can be reused.
    
    %initialise main bits:
    colRHS=zeros(length(X),1);
    colMatrix=zeros(length(X),length(Vbasis.el));
    for m=1:length(X)
        %manually do first entry of row
        [colMatrix(m,1), quadData] = colEvalV2(Operator, Vbasis.el(1), Vbasis.elSide(1), Xstruct(m), Nquad,[], standardQuadFlag);
        for n=2:length(Vbasis.el)
           if Vbasis.el(n).pm == Vbasis.el(n-1).pm && isequal(Vbasis.el(n).supp,Vbasis.el(n-1).supp)% && 2+2==5
               %reuse quadrature from previous iteration of this loop,
               %(phase and domain are the same)
               colMatrix(m,n) = colEvalV2(Operator, Vbasis.el(n), Vbasis.elSide(n), Xstruct(m), Nquad, quadData, standardQuadFlag);
               1+1;
           else
               %get fresh quadrature data
               [colMatrix(m,n), quadData] = colEvalV2(Operator, Vbasis.el(n), Vbasis.elSide(n), Xstruct(m), Nquad,[], standardQuadFlag);
           end
        end 
        fX = f.eval(X(m),Xside(m));
        if ~standardBEMflag
           Ystruct = Xstruct;
           Ystruct(m).distMeshL = Ystruct(m).distSideL;
           Ystruct(m).distMeshR = Ystruct(m).distSideR;
         %  SPsiX =  colEval(Operator, GOA, GOA.illumSides, X(m), Xside(m), X(m), X(1+length(X)-m), Nquad,[], standardQuadFlag);
           SPsiX = colEvalV2(Operator, GOA, GOA.illumSides, Ystruct(m), Nquad,[], standardQuadFlag);
           colRHS(m)  = fX - SPsiX;
        else
           colRHS(m)  = fX;
        end
        if messageFlag
            fprintf('\n%.1f%%',100*m/length(X));
        end
    end
    
    %use least squares with Matlab's built in SVD to get coefficients
    coeffs=colMatrix\colRHS;
    %coeffs = pseudo_backslash(colMatrix, colRHS, 1E-5);
    v_N=Projection(coeffs,Vbasis);
    
    if messageFlag
        toc
    end
    
end