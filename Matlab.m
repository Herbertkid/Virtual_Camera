

clear;
% % main step code%
% % %--------------------------------------------------%
% % 
% % %################## Edit Section #####################%
% % % The image will automatically be saved in the same folder 
% % % You can change 'RGB' to 'HSV'
mode = 'RGB';
% % 
% % % Set focal length ie. 3, 5, 7
f = 5; 
% % 
% % % Set the camera you want from 1 to 3
cameranumber = 1;
% % 
% % % You can set whether to turn on/off figure in matlab 
figurevisable = 'on';
% % %######################################################%
% % 
% %Creat 3d scene
[xyzpoints,color] = creat3dscene(2000, 2000, ...
    mode, 'off');
% 
% % % Do not change this function
% % % If you want to add transformation matrix,
% % please add in this function
Qoc = transformpoints(cameranumber);
% 
% % Call camera to take picture
% % It will automatically be saved in the same folder 

%Create rangesensor
rangesensor(xyzpoints, color, Qoc, figurevisable); 
%Create Cartesian depth map
[depthmap,maxdepth] = cartesiandepthmap(xyzpoints, f, Qoc,cameranumber, mode, figurevisable);
% Create radial depth map
[depthmap,maxdepth] = radialdepthmap(xyzpoints, f, Qoc,cameranumber, mode, figurevisable);
%--------------------------------------------------%
%End of main step code



% Function create a 3d scence
function [xyzpoints,color] = creat3dscene(width, height, mode, figurevisable)
% Set the x,y,z points
% parameter is x, y, z in real world
% Use repmat function to generate 1000x1000x3 matric, which the 3rd
xobj1 = repmat((-width/2:1:width/2-1)',1,width);    % xobj1 in matrix is colmun
yobj1 = repmat((height/2-1:-1:-height/2),height,1); % yobj1 in matrix is row
zobj1 = (100*sin(xobj1./150)); 
xyzpoints(:,:,1) = xobj1;  % x
xyzpoints(:,:,2) = yobj1;  % y
xyzpoints(:,:,3) = zobj1;  % z

%Set color:
HSV(:,:,1) = 0.5*(xobj1./1000+1);    % H
HSV(:,:,2) = ones(2000,2000);        % S
HSV(:,:,3) = 0.5*(-yobj1./1000+1);   % v
RGB = hsv2rgb(HSV);

if mode == 'RGB'
%Plot the 3D cloud:
    ptCloud = pointCloud(xyzpoints,'Color',RGB );
    figure('Name','Sence','visible', figurevisable); % off/on to show figure
    ax = pcshow(ptCloud,"BackgroundColor",[1 1 1]);
    title('3D Cloud');
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    
    % Change the Y axis's direction from top to down as required.
    set(ax, 'Ydir', 'reverse');
    saveas(gcf,'scence-rgb.jpg');% save picture as output
    color = RGB;
elseif mode == 'HSV'
    %Plot the 3D cloud:
    ptCloud = pointCloud(xyzpoints,'Color',HSV );
    figure('Name','Sence','visible', figurevisable); % off/on to show figure
    ax = pcshow(ptCloud,"BackgroundColor",[1 1 1]);
    title('3D Cloud');
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    
    % Change the Y axis's direction from top to down as required.
    set(ax, 'Ydir', 'reverse');
    saveas(gcf,'scence-hsv.jpg');% save picture as output
    color = HSV;
end
end

% Create radial depth map
function [depthmap,maxdepth] = radialdepthmap(xyzpoints, f, Qoc1,cameranumber, mode, figurevisable)
% Non-inverting perspective projection model                                   
p = [1 0 0 0; 
     0 1 0 0;
     0 0 1 0;
     0 0 1/f 0];   % model

% Initalize the outpur virtual image
depthmap = ones(480,640,3);
depthmap1 = ones(480,640);
% depthmap = depthmap/2;

s1 = size(Qoc1);
s2 = size(xyzpoints);
tobj1 = ones(s2(1),s2(2));

%Transform by transformation matrix
for m = 1:s1(1)
    if m == 1
        xobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 2
        yobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 3
        zobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4); 
    end
end

xobjp = xobj2./(zobj2*p(4,3)); %scale by real mm
yobjp = yobj2./(zobj2*p(4,3)); %scale by real mm

%Start: change to pixel in camera plane
lengthu = 12.7/640; 
widthu = 12.7/480;  
xp = round(xobjp./lengthu);
yp = round(yobjp./widthu);
%Finish: change to pixel in camera plane

%sample data from matrix
po(:,:,1) = xp;
po(:,:,2) = yp;
po(:,:,3) = zobj2;
po(:,:,4) = xobj2;
po(:,:,5) = yobj2;

[C1,ia1,ic1] = unique(po(:,:,1), 'rows');
[C2,ia2,ic2] = unique(po(:,:,2)', 'rows');
pfinal = po(ia1,ia2,:);
pfinal(:,:,1) = pfinal(:,:,1)+320;
pfinal(:,:,2) = pfinal(:,:,2)+240;

pr(:,:,1) = reshape(pfinal(:,:,1)',1,numel(pfinal(:,:,1)));
pr(:,:,2) = reshape(pfinal(:,:,2)',1,numel(pfinal(:,:,2)));
pr(:,:,3) = reshape(pfinal(:,:,3)',1,numel(pfinal(:,:,3)));
pr(:,:,4) = reshape(pfinal(:,:,4)',1,numel(pfinal(:,:,4)));
pr(:,:,5) = reshape(pfinal(:,:,5)',1,numel(pfinal(:,:,5)));

s3 =size(pr);
for m=1:s3(2)
    xf = pr(1,m,2); % y axis
    yf = pr(1,m,1); % x axis
    if xf>0 && xf< 480 && yf>0 && yf<640
        depthmap(xf,yf,1) = pr(1,m,3);
        depthmap(xf,yf,2) = pr(1,m,4);
        depthmap(xf,yf,3) = pr(1,m,5);
        depthmap1(xf,yf) = sqrt((pr(1,m,3))^2+(pr(1,m,4))^2+(pr(1,m,5))^2);
    end
end
%Finish sampling
maxdepth = (max(max(depthmap1)));
fprintf("maxdepth in radial depth map %f:\n",maxdepth)
% depthmapfinal = depthmap/maxdepth;
%Set image name
imagename = append('radialdepthmap', num2str(cameranumber), '_', mode, '_f', num2str(f),'.jpg');
titlename = append('radialdepthmap', num2str(cameranumber),' ', mode, ' f', num2str(f));
%take picture from camera
% off/on to show figure
figure('Name','radialdepthmap','visible', figurevisable); imshow(depthmap1,[1,maxdepth]);
title(titlename);
xlabel('X');
ylabel('Y');
axis on;
grid off;
xticks([0 40 80 120 160 200 240 280 320 360 400 440 480 520 560 600 640]);
yticks([0 40 80 120 160 200 240 280 320 360 400 440 480]);
set(gca, 'YTickLabel', get(gca, 'YTick') - 240);
set(gca, 'XTickLabel', get(gca, 'XTick') - 320 );
saveas(gcf,imagename);% save picture as output
end

%Create Cartesian depth map
function [depthmap,maxdepth] = cartesiandepthmap(xyzpoints, f, Qoc1,cameranumber, mode, figurevisable)
% Non-inverting perspective projection model                                   
p = [1 0 0 0; 
     0 1 0 0;
     0 0 1 0;
     0 0 1/f 0];   % model

% Initalize the outpur virtual image
depthmap = ones(480,640);
% depthmap = depthmap/2;

s1 = size(Qoc1);
s2 = size(xyzpoints);
tobj1 = ones(s2(1),s2(2));

%Transform by transformation matrix
for m = 1:s1(1)
    if m == 1
        xobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 2
        yobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 3
        zobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4); 
    end
end

xobjp = xobj2./(zobj2*p(4,3)); %scale by real mm
yobjp = yobj2./(zobj2*p(4,3)); %scale by real mm

%Start: change to pixel in camera plane
lengthu = 12.7/640; 
widthu = 12.7/480;  
xp = round(xobjp./lengthu);
yp = round(yobjp./widthu);
%Finish: change to pixel in camera plane

%sample data from matrix
po(:,:,1) = xp;
po(:,:,2) = yp;
po(:,:,3) = zobj2;

[C1,ia1,ic1] = unique(po(:,:,1), 'rows');
[C2,ia2,ic2] = unique(po(:,:,2)', 'rows');
pfinal = po(ia1,ia2,:);
pfinal(:,:,1) = pfinal(:,:,1)+320;
pfinal(:,:,2) = pfinal(:,:,2)+240;

pr(:,:,1) = reshape(pfinal(:,:,1)',1,numel(pfinal(:,:,1)));
pr(:,:,2) = reshape(pfinal(:,:,2)',1,numel(pfinal(:,:,2)));
pr(:,:,3) = reshape(pfinal(:,:,3)',1,numel(pfinal(:,:,3)));

s3 =size(pr);
for m=1:s3(2)
    xf = pr(1,m,2); % y axis
    yf = pr(1,m,1); % x axis
    if xf>0 && xf< 480 && yf>0 && yf<640
        depthmap(xf,yf) = pr(1,m,3);
    end
end
%Finish sampling
maxdepth = (max(max(depthmap)));
fprintf("maxdepth in Cartesian depth map %f:\n",maxdepth)
% depthmapfinal = depthmap/maxdepth;
%Set image name
imagename = append('depthmap', num2str(cameranumber), '_', mode, '_f', num2str(f),'.jpg');
titlename = append('depthmap', num2str(cameranumber),' ', mode, ' f', num2str(f));
%take picture from camera
% off/on to show figure
figure('Name','depthmap','visible', figurevisable); imshow(depthmap,[1,maxdepth]);
title(titlename);
xlabel('X');
ylabel('Y');
axis on;
grid off;
xticks([0 40 80 120 160 200 240 280 320 360 400 440 480 520 560 600 640]);
yticks([0 40 80 120 160 200 240 280 320 360 400 440 480]);
set(gca, 'YTickLabel', get(gca, 'YTick') - 240);
set(gca, 'XTickLabel', get(gca, 'XTick') - 320 );
saveas(gcf,imagename);% save picture as output
end

% Create range sensor
function rangesensor(xyzpoints, color, Qoc1, figurevisable)
s1 = size(Qoc1);
s2 = size(xyzpoints);
tobj1 = ones(s2(1),s2(2));
for m = 1:s1(1)
    if m == 1
        xobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 2
        yobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4);
    elseif m == 3
        zobj2 = xyzpoints(:,:,1).*Qoc1(m,1) + xyzpoints(:,:,2).*Qoc1(m,2)+ xyzpoints(:,:,3).*Qoc1(m,3)+ tobj1.*Qoc1(m,4); 
    end
end
po(:,:,1) = xobj2;
po(:,:,2) = yobj2;
po(:,:,3) = zobj2;
po(:,:,4) = color(:,:,1);
po(:,:,5) = color(:,:,2);
po(:,:,6) = color(:,:,3);
[C1,ia1,ic1] = unique(po(:,:,1), 'rows');
[C2,ia2,ic2] = unique(po(:,:,2)', 'rows');
pfinal = po(ia1,ia2,:);
pr(:,:,1) = reshape(pfinal(:,:,1)',1,numel(pfinal(:,:,1)));
pr(:,:,2) = reshape(pfinal(:,:,2)',1,numel(pfinal(:,:,2)));
pr(:,:,3) = reshape(pfinal(:,:,3)',1,numel(pfinal(:,:,3)));
pr(:,:,4) = reshape(pfinal(:,:,4)',1,numel(pfinal(:,:,4)));
pr(:,:,5) = reshape(pfinal(:,:,5)',1,numel(pfinal(:,:,5)));
pr(:,:,6) = reshape(pfinal(:,:,6)',1,numel(pfinal(:,:,6)));
ptCloud = pointCloud(pr(:,:,1:3),'Color',pr(:,:,4:6));
figure('Name','rangesensor','visible', figurevisable); % off/on to show figure
ax = pcshow(ptCloud,"BackgroundColor",[1 1 1]);
title('Range Sensor');
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');

% Change the Y axis's direction from top to down as required.
set(ax, 'Ydir', 'reverse');
saveas(gcf,'rangesensor-rgb.jpg');% save picture as output
end


function Qoc = transformpoints(cameranumber)
% Set transformation matrix
% Camera 1
Qoc1 = [1 0 0 0; 
        0 1 0 0; 
        0 0 1 1000; 
        0 0 0 1];
% Camera 2
Qcc2 = [0.866 0 -0.5 400;
        0 1 0 0;
        0.5 0 0.866 -600;
        0 0 0 1];
% Camera 3
Qcc3 = [0.7071 0 0.7071 -1200;
        0 1 0 0;
        -0.7071 0 0.7071 0;
        0 0 0 1];
%//////////////////////////////
% You can add camera matrix here
% Then add elseif statement
%/////////////////////////////

if cameranumber == 1
    Qoc = Qoc1;
elseif cameranumber == 2
    Qoc = inv(Qcc2)*Qoc1;
elseif cameranumber == 3
    Qoc = inv(Qcc3)*Qoc1;
end
end
