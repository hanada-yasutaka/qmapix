classdef FundamentalState < matlab.mixin.SetGet & SystemInfo
    % FundamentalState is a class of a 1-dim. wavefunction with position $q$ and
    % momentum $p$ representations.
    %
    properties (SetAccess = protected)
        basis {mustBeMember(basis,{'q','p'})} = 'p' % basis (representation) of wavefunction                 
        system % instance of the class SystemInfo
        eigenvalue {mustBeNumeric} = NaN % eigenvalue data
        x
        y (:,1) {mustBeNumeric} = [] % <x|¥psi> where x is $q$ or $p$
    end
    
    
    methods
        function obj = FundamentalState(system, vec, basis, eigenvalue)
            if ~isa(system, 'SystemInfo')
                error("scl must be SystemInfo class")
            end
            
            obj@SystemInfo(system.dim, system.domain)     
            obj.system = system;
                        
            if exist('vec', 'var')
                obj.y = vec;
                obj.basis = basis;
                if strcmp(basis, 'q')
                    obj.x = obj.q;
                elseif strcmp(basis, 'p')
                    obj.x = obj.p;
                end                
            end
                            
            
            if exist('eigenvalue', 'var')
                obj.eigenvalue = eigenvalue;
            end
        end
        
        function obj = tostate(obj, vec)
            % convert to vector array to state             
            obj = FundamentalState(obj.system, vec, obj.basis);
        end
        
        function obj = double(obj)
            % truncate to double 
            system = SystemInfo(obj.dim, double(obj.domain) );
            obj = FundamentalState(system, double(obj.y), obj.basis);            
        end
        
        function obj = q2p(obj)
            vec = fft(obj.y);
            obj = FundamentalState(obj.system, vec/sqrt(obj.dim), 'p' );
        end
        
        function obj = p2q(obj)
            vec = ifft(obj.y);
            obj = FundamentalState(obj.system, vec/sqrt(obj.dim), 'q');
        end
        
        function y = abs2(obj)
            % return |<x|psi>|^2
            y = abs( obj.y .* conj(obj.y) );
        end
        
        function y = norm(obj)
            % overload built-in norm function to  <¥psi|¥psi>
            y = norm( obj.y );
        end
        
        function display(obj)
            % overload built-in display function to display <x|¥psi>
            display( obj.y )
        end
        
        function disp(obj)
            % overload built-in disp function to display <x|¥psi>            
            disp( obj.y );
        end
        
        function obj = times(v1, v2)
            % overload built-in times ( .* ) function to <v1|v2>
            basisconsistency(v1, v2);            
            z = inner(v1, v2);
            obj = FundamentalState(v1.system, z, v1.basis);            
        end
        
        function obj = plus(v1, v2)
            % overload built-in plus ( + ) function to |v1> + |v2>
            basisconsistency(v1,v2);            
            if strcmp(class(v2), 'FundamentalState')
                v2 = v2.y;
            end
            v3 = v1.y + v2;
            obj = FundamentalState(x.system, v3, v1.basis);
        end
        
        function obj = minus(v1, v2)
            % overload built-in minus ( - ) function to |v1> - |v2>            
            basisconsistency(v1,v2);            
            if strcmp( class(v2), 'FundamentalState')
                v2 = v2.y;
            end
            v3 = v1.y - v2;
            obj = FundamentalState(x.system, v3, v1.basis);
        end
            
        
        function v3 = inner(v1, v2)
            % return < v1 | v2 >
            if strcmp( class(v2), 'FundamentalState')
                v2 = v2.y;
            elseif size(v1.y) ~= size(v2.y)
                error("size must be same");
            end
            % dot(v1, v2) = abs2( sum( conj(v1) .* v2) )
            v3 = dot(v1.y , v2);
        end
        
        function obj = normalize(obj)
            v = obj.y;
            a = dot(v, v);
            obj = FundamentalState(obj.system, v/sqrt(a), obj.basis);
        end
        
        function y = zeros(obj)
            v = zeros(1, obj.dim, class(obj.domain));
            y = FundamentalState(obj.system, v, obj.basis);
        end
        
        function obj = coherent(obj, qc, pc, periodic)
            arguments
                obj;
                qc {mustBeReal};
                pc {mustBeReal};
                periodic {mustBeNumericOrLogical} = true;
            end
            
            if periodic
                v = csp(obj.q, obj.hbar, obj.domain(1,:), qc, pc, 5);
                a = dot(v, v);
                obj = FundamentalState(obj.system, v / sqrt(a), 'q');
            elseif ~periodic
                v = cs(obj.q, obj.hbar, qc, pc);
                a = dot(v, v);
                obj = FundamentalState(obj.system, v / sqrt(a), 'q');
                obj.periodic = false;
            else
                error("periodic must be true/false");
            end
            
        end
                
        function [X, Y, mat] = hsmrep(obj, gridnum, range)
            arguments
                obj;
                gridnum {mustBeInteger, mustBePositive} = 50;                
                range {mustBeReal} = [obj.domain(1,1) obj.domain(1,2); obj.domain(2,1), obj.domain(2,2)];
            end
            v = obj.y;
            x = transpose(obj.q);
            qc = linspace(obj.domain(1,1), obj.domain(1,2), gridnum);
            pc = linspace(obj.domain(2,1), obj.domain(2,2), gridnum);
            [X,Y] = meshgrid(qc,pc);
            mat = zeros(gridnum, class(v));
            
            if obj.periodic
                csfun = @(qc, pc) csp(x, obj.hbar, obj.domain(1,:), qc, pc, 5);                
            else
                csfun = @(qc, pc)  cs(x, obj.hbar, qc, pc);
            end
            
            for i = 1:length(qc)
                for j = 1:length(pc)
                    cs = transpose( csfun(qc(j), pc(i)) );
                    % dot(c, v) = abs2( sum( conj(c) .* v) )
                    mat(i,j) = abs2( dot(cs, v) );

                end
            end
        end
        

        
        function obj = delta(obj)
            
            obj.y=1;
        end
        
        
        function save_state()
        end
        
        function save_eigs()
        end
        
       %% operator overload
        
        %function display(obj)
        %    display(obj.y);
        %end
        
        %function disp(obj)
        %    disp(obj.y);
        %end
            
       
        %function y = plus(obj1, obj2)
        %    isstate(obj1, obj2);
        %    data = obj1.data + obj2.data;
        %    y = FundamentalState(obj1.dim, obj1.domain, obj1.basis, data);
        %end
        %
        %function isstate(obj1, obj2)
        %    if ~isa(obj1, 'FundamentalState')
        %        error(sprintf('object must be FundamentalState' ));
        %    elseif exist('obj2', 'var') && ~isa(obj2, 'FundamentalState')
        %        error(sprintf('object must be FundamentalState', getobjname(obj1) ));
        %    end
        %end
        %%%        
    end
end

function y = cs(x, hbar, qc, pc)
  arguments
      x {mustBeNumeric};      
      hbar {mustBeReal};
      qc {mustBeReal};
      pc {mustBeReal};
  end
  if isrow(x)
      x = x.';
  end  
  y = exp( -(x - qc) .^ 2 /(2 * hbar) + 1j*(x - qc) * pc / hbar);
end

function y = csp(x, hbar, qdomain, qc, pc, partition)
  arguments
      x {mustBeNumeric};
      hbar {mustBeReal};
      qdomain (1,2) {mustBeReal};
      qc {mustBeReal};
      pc {mustBeReal};
      partition {mustBeInteger} = 5; % mustbe odd number
  end
  
  if mod(partition, 2) == 0
      error("partition must be odd integer");
  end
  
  if isrow(x)
      x = x.';
  end
  
  dim = length(x);
  width = qdomain(1,2) - qdomain(1,1);
  blk = fix(partition/2);
  
  qmin = qdomain(1,1) - blk*width;
  qmax = qdomain(1,2) + blk*width;
  q = linspace(qmin, qmax, partition*dim);
  %q = q(1:end-1);
  
  vec = cs(q, hbar, qc, pc);
  vec = reshape(vec, dim, partition);
  y = zeros(dim, 1, class(x));
  for i = 1:partition
      y = y + vec(:,i);
  end
end

function y = abs2(x)
  y = abs( conj(x) .* x);
end 
   
function basisconsistency(v1, v2)
  if ~strcmp(v1.basis, v2.basi)
      error("basis must be same");
  end
end
