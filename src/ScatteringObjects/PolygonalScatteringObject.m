classdef (Abstract) PolygonalScatteringObject < handle
    %abstract class of scattering objects, such as screens, convex
    %polygons, etc
    
    properties
        component = edge();%just to initialise it...
        numComponents
        vertices
        internalAngle
        Lipschitz
    end
    
    methods
        val = normal(self,s);
        
        function equivs = getSymmetries(self)
            %determine maps between edges
            for n = 1:self.numComponents
                mid_n = (self.component(n).P2 + self.component(n).P1)/2;
                for m = 1:self.numComponents
                    mid_m = (self.component(m).P2 + self.component(m).P1)/2;
                    Y{n,m}.midTranslate = mid_m - mid_n;
                    Y{n,m}.rotate = self.internalAngle(m,n);
                    Y{n,m}.oldLength = self.component(n).L;
                    Y{n,m}.newLength = self.component(n).L;
                end
            end
            
            %now look to see if maps are the same
            equivs_init = reshape(1:self.numComponents^2,[self.numComponents self.numComponents]);
            equivs = equivs_init;
            errTol = 1e-12;
            %do this lots of times to account for every possible equivalence as many times
            %as is needed
            for pointlessCounter = 1: (self.numComponents^2)
                for n = 1:self.numComponents
                    for m = 1:self.numComponents
                        for n_ = 1:self.numComponents
                            for m_ = 1:self.numComponents
                                if norm(Y{n,m}.midTranslate - Y{n_,m_}.midTranslate)<errTol && abs(Y{n,m}.rotate - Y{n_,m_}.rotate)<errTol...
                                   && abs(Y{n,m}.oldLength - Y{n_,m_}.oldLength)<errTol && abs(Y{n,m}.newLength - Y{n_,m_}.newLength)<errTol
                                    equivs(n_,m_) = equivs(n,m);
                                elseif norm(Y{n,m}.midTranslate + Y{n_,m_}.midTranslate)<errTol && abs(Y{n,m}.rotate - Y{n_,m_}.rotate)<errTol...
                                       && abs(Y{n,m}.oldLength - Y{n_,m_}.newLength)<errTol && abs(Y{n,m}.newLength - Y{n_,m_}.oldLength)<errTol
                                    equivs(n_,m_) = -equivs(n,m);
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function draw(self)
           for n=1:self.numComponents
               self.component(n).draw();
               hold on;
           end
           hold off;
        end
    
        function val = trace(self,s,index)
            val = self.component{index}.trace(s);
        end
        
        function val = dist(self,s,sIndex,t,tIndex)
            val = abs(self.trace(s,sIndex)-self.trace(t,tIndex));
        end
         
        function R = distAnal(self,s,t,deriv,sGEt,sIndex,tIndex)
%             if length(s)>1
%                 error('first input must be a single param value');
%             end
            
            s=s(:); t=t(:);
            
            if sIndex == tIndex
                %sGEt = min(s)>=max(t);
                if sGEt
                    pm = 1;
                else
                    pm = -1;
                end
                switch deriv
                    case 0
                        R = pm*(s-t);
                    case 1
                        R = -pm;
                    otherwise
                        R = 0;
                end
            else
                x = self.component(sIndex).trace(s);
                y = self.component(sIndex).trace(t);
                yMx = -[ (x(1)-y(:,1))  (x(2)-y(:,2)) ];
                dy = self.component(sIndex).dSv;
                R0 = sqrt( (x(1) - y(:,1) ).^2 + (x(2) - y(:,2) ).^2);
                switch deriv
                    case 0 
                        R = R0;
                    case 1
                        R = (dy*(yMx.')).'./R0;
                    case 2
                        %account for 2nd derivative bug:
                        if length(t) == 1
                            yMx1 = yMx(1);
                            yMx2 = yMx(2);
                        else
                            yMx1 = yMx(1,:);
                            yMx2 = yMx(2,:);
                        end
                        R = - dy(1)*((dy(1)*(2*x(1) - 2*y(:,1)).^2)./(4*R0.^3) - dy(1)./R0 + (dy(2)*(2*x(1) - 2*y(:,1)).*(2*x(2) - 2*y(:,2)))./(4*R0.^3)) - dy(2)*((dy(2)*(2*x(2) - 2*y(:,2)).^2)./(4*R0.^3) - dy(2)./R0 + (dy(1)*(2*x(1) - 2*y(:,1)).*(2*x(2) - 2*y(:,2)))./(4*R0.^3));
                        
                    case 3
                        error('Havent coded derivtives this high yet')
                end
                %alternative option if the sides meet at a vertex, or are
                %close together
            end
        end
    end
end

