function grady = ddy(field,gmtry)
% according to B2.5/src/b2plot/b2plot.F, case('ddy')
% fit for field with dimension (nx+2,ny+2) or (nx+2,ny+2,ns)
% by Jin Guo, 2020

[nxd,nyd,ns] = size(field);  nx=nxd-2;  ny=nyd-2;
[nxd1,nyd1] = size(gmtry.hx); nx1=nxd1-2; ny1=nyd1-2;  % size of mesh
if nx~=nx1 || ny~=ny1
    error('size of input field is not consistent with input gmtry');
else
    fprintf('\tCalculate ddy: assumed nx=%d, ny=%d, ns=%d\n',nx,ny,ns);
end
hy1 = gmtry.hy .* gmtry.qz(:,:,2);  % radial width of cell projection perpendicular to x direction
for is = 1:ns
    for ix = 1:nxd
        for iy = 1:nyd
            iyb = gmtry.bottomiy(ix,iy);  iyb = iyb+2;  % the min gmtry.bottomiy is -2
            iyt = gmtry.topiy(ix,iy);  iyt = iyt+2;  % the min gmtry.topiy is 0
            if iyb == -2+2
                grady(ix,iy,is) = (field(ix,iyt,is)-field(ix,iy,is))/((hy1(ix,iy)+hy1(ix,iyt))/2);
            elseif iyt == nyd+1
                grady(ix,iy,is) = (field(ix,iy,is)-field(ix,iyb,is))/((hy1(ix,iy)+hy1(ix,iyb))/2);
            else
                grady(ix,iy,is) = (field(ix,iyt,is)-field(ix,iyb,is))/(hy1(ix,iy)+(hy1(ix,iyb)+hy1(ix,iyt))/2);
            end
        end
    end
end

