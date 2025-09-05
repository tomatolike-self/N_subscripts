function gradx = ddx(field,gmtry)
% according to B2.5/src/b2plot/b2plot.F, case('ddx')
% fit for field with dimension (nx+2,ny+2) or (nx+2,ny+2,ns)
% by Jin Guo, 2020

[nxd,nyd,ns] = size(field);  nx=nxd-2;  ny=nyd-2;
[nxd1,nyd1] = size(gmtry.hx); nx1=nxd1-2; ny1=nyd1-2;  % size of mesh
if nx~=nx1 || ny~=ny1
    error('size of input field is not consistent with input gmtry');
else
    fprintf('\tCalculate ddx: assumed nx=%d, ny=%d, ns=%d\n',nx,ny,ns);
end
hx = gmtry.hx;  % poloidal length of cell
for is = 1:ns
    for ix = 1:nxd
        for iy = 1:nyd
            ixl = gmtry.leftix(ix,iy);  ixl = ixl+2;  % the min gmtry.leftix is -2
            ixr = gmtry.rightix(ix,iy);  ixr = ixr+2;  % the min gmtry.rightix is 0
            if ixl == -2+2
                gradx(ix,iy,is) = (field(ixr,iy,is)-field(ix,iy,is))/((hx(ix,iy)+hx(ixr,iy))/2);
            elseif ixr == nxd+1
                gradx(ix,iy,is) = (field(ix,iy,is)-field(ixl,iy,is))/((hx(ix,iy)+hx(ixl,iy))/2);
            else
                gradx(ix,iy,is) = (field(ixr,iy,is)-field(ixl,iy,is))/(hx(ix,iy)+(hx(ixl,iy)+hx(ixr,iy))/2);
            end
        end
    end
end

