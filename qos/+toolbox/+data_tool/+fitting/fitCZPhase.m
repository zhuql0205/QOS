function phi = fitCZPhase(Pm)
% chi = sqc.qfcns.processTomoData2Rho(Pm);

    function y = fitFunc(phi)
        PIdeal = sqc.qfcns.CZP(phi);
        D = (real(PIdeal) - Pm).^2;
        y = sum(D(:));
    end
    
    phi = qes.util.fminsearchbnd(@fitFunc,0,-pi,pi);    

end