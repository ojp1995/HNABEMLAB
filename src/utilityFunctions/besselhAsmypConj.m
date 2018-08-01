function [H, Hosc, HnonOsc] = besselhAsmypConj(Hvk, kind, z)
%uses conjugation to determine values of Hankel function in the region
%where asymptotic estimates are not valid

    negArgInds = find(angle(z)<0);
    posArgInds = find(angle(z)>=0);

    if kind == 1
        %use conjugation trick:
        [H(negArgInds), Hosc(negArgInds), HnonOsc(negArgInds)] = Hvk(3-kind,conj(z));
        H(negArgInds) = conj(H(negArgInds));
        Hosc(negArgInds) = conj(Hosc(negArgInds));
        HnonOsc(negArgInds) = conj(HnonOsc(negArgInds));
        %the standard expansion should work here:
        [H(posArgInds), Hosc(posArgInds), HnonOsc(posArgInds)] = Hvk(kind,z);
    elseif kind == 2
        error('Not ready for second kind Hankel functions yet');
    end

end

