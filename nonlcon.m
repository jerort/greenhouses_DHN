function [c,ceq] = nonlcon(x,A,b)
%Restricciones lineales como no-lineales
c = A*x'-b;
ceq =[];
end