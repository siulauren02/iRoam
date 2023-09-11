clc;
clear;

%% Shape and color
count = 1;
for num=1:98
    name = "./rawData/largeTest ("+num+").PNG";
   IM = imread(name);
   info = imfinfo(name);
   if isfield(info,'Orientation')
       orient = info(1).Orientation;
%% Corrects orientation of picture
       switch orient
        case 1
        %normal, leave the data alone
        case 2
            IM = IM(:,end:-1:1,:);         %right to left
        case 3
            IM = IM(end:-1:1,end:-1:1,:);  %180 degree rotation
        case 4
            IM = IM(end:-1:1,:,:);         %bottom to top
        case 5
            IM = permute(IM, [2 1 3]);     %counterclockwise and upside down
        case 6
            IM = rot90(IM,3);              %undo 90 degree by rotating 270
        case 7
            IM = rot90(IM(end:-1:1,:,:));  %undo counterclockwise and left/right
        case 8
            IM = rot90(IM);                %undo 270 rotation by rotating 90
        otherwise
            warning(sprintf('unknown orientation %g ignored\n', orient));
       end
   end
   RGB = IM;
    redStats = newHSVred(RGB);
    whiteStats = HSVwhite(RGB);
    [rows, columns,color] = size(RGB);
    area = rows*columns;
 %% Checks for colored areas and their shapes and then assigns a flag number
 for i=1:length(redStats)
        if redStats(i).BoundingBox(3)> redStats(i).BoundingBox(4)&&redStats(i).BoundingBox(3)< 5*redStats(i).BoundingBox(4)&&redStats(i).Area>area/10000
            parameter = [redStats(i).BoundingBox(1)-redStats(i).BoundingBox(3)*0.5,redStats(i).BoundingBox(2)-redStats(i).BoundingBox(4)*0.5,2*redStats(i).BoundingBox(3),7*redStats(i).BoundingBox(4)];
            cropped = imcrop(RGB, parameter);
            flag = 0;
            for j = 1:length(whiteStats)
                closeWhite = whiteStats(j).BoundingBox(3)< 2*whiteStats(j).BoundingBox(4)&&5*whiteStats(j).BoundingBox(3)> whiteStats(j).BoundingBox(4)&&whiteStats(j).Centroid(1)>redStats(i).BoundingBox(1)&&whiteStats(j).Centroid(1)<redStats(i).BoundingBox(1)+redStats(i).BoundingBox(3)&&(whiteStats(j).Centroid(2)-redStats(i).Centroid(2)>0)&&(whiteStats(j).Centroid(2)-redStats(i).Centroid(2)<whiteStats(j).BoundingBox(4)*2)&&whiteStats(j).BoundingBox(3)<2*redStats(i).BoundingBox(3)&&(whiteStats(j).BoundingBox(2)-redStats(i).BoundingBox(2))<redStats(i).BoundingBox(4)*1.5;
                
                for k = 1:length(redStats)
                    closeRed = redStats(k).BoundingBox(3)< 6*redStats(k).BoundingBox(4)&&1.5*redStats(k).BoundingBox(3)> redStats(k).BoundingBox(4)&&redStats(k).Centroid(1)>redStats(i).BoundingBox(1)&&redStats(k).Centroid(1)<redStats(i).BoundingBox(1)+redStats(i).BoundingBox(3)&&i~=k&&redStats(k).Centroid(2)>redStats(i).Centroid(2)+whiteStats(j).BoundingBox(4)/2&&redStats(k).Centroid(2)<redStats(i).Centroid(2)+2*whiteStats(j).BoundingBox(4)&&redStats(k).Area>(redStats(i).Area/20)&&redStats(k).Area<redStats(i).Area*1.5&&redStats(k).BoundingBox(2)>whiteStats(j).Centroid(2);
                    if closeWhite&&closeRed
                        flag = 3;
                        break;
                    
                    elseif closeRed
                        flag = 2;
                    elseif closeWhite&&flag==0
                        flag = 1;
                    end   

                end
                if flag == 3
                    break;
                end                
            end
            
            for k  = 1:length(redStats)
            closeRed = redStats(k).BoundingBox(3)< 6*redStats(k).BoundingBox(4)&&6*redStats(k).BoundingBox(3)> redStats(k).BoundingBox(4)&&redStats(k).Centroid(1)>redStats(i).BoundingBox(1)-redStats(i).BoundingBox(3)/2&&redStats(k).Centroid(1)<redStats(i).BoundingBox(1)+redStats(i).BoundingBox(3)/2+redStats(i).BoundingBox(3)&&i~=k&&redStats(k).Centroid(2)>redStats(i).Centroid(2)+redStats(i).BoundingBox(4)&&redStats(k).Centroid(2)<redStats(i).Centroid(2)+8*redStats(i).BoundingBox(4)&&redStats(k).Area>(redStats(i).Area/20)&&redStats(k).Area<redStats(i).Area*2&&redStats(k).BoundingBox(2)>redStats(i).BoundingBox(2)+redStats(i).BoundingBox(4);
                
                if closeRed&&flag<2
                        flag = 2;
                end
            end
%% Assigns Confidence Levels Respective File Names
            if flag == 3
                imwrite(cropped,"./preliminaryResult/"+num+'highcropped'+i+".png");
                locations(count).name = num+"highcropped"+i+".png";
                locations(count).level = 2;
                locations(count).ishigh = 1;
                locations(count).number = num;
                locations(count).ref = i;
                locations(count).rectangle = parameter;
                count = count+1;
            elseif flag == 2
                imwrite(cropped,"./preliminaryResult/"+num+'midcropped'+i+".png");
                locations(count).name = num+"midcropped"+i+".png";
                locations(count).level = 1;
                locations(count).ishigh = 0;
                locations(count).number = num;
                locations(count).ref = i;
                locations(count).rectangle = parameter;
                count = count+1;
            elseif flag ==1
                imwrite(cropped,"./preliminaryResult/"+num+'lowcropped'+i+".png");
                locations(count).name = num+"lowcropped"+i+".png";
                locations(count).level = 0;
                locations(count).ishigh = 0;
                locations(count).number = num;
                locations(count).ref = i;
                locations(count).rectangle = parameter;
                count = count+1;
            end
            

            
        end
 end
end

 save('./reference.mat','locations');


%% Compute SURF features on reference image
ref_im_gray1 = csvread("ref1.csv");
ref_pts1 = detectSURFFeatures(ref_im_gray1);
[ref_features1, ref_validPts1] = extractFeatures(ref_im_gray1, ref_pts1);
% figure;
% imshow(ref_im);
% hold on; 
% plot(ref_pts.selectStrongest(100));

%% Compute SURF features on reference image 2
ref_im_gray2 = csvread("ref2.csv");
ref_im_gray2 = uint8(ref_im_gray2);
ref_pts2 = detectSURFFeatures(ref_im_gray2);
[ref_features2, ref_validPts2] = extractFeatures(ref_im_gray2, ref_pts2);
% figure;
% imshow(ref_im2);
% hold on; 
% plot(ref_pts2.selectStrongest(100));
%% Compute SURF features on reference image 3
ref_im_gray3 = csvread("ref3.csv");
ref_pts3 = detectSURFFeatures(ref_im_gray3);
[ref_features3, ref_validPts3] = extractFeatures(ref_im_gray3, ref_pts3);
% figure;
% imshow(ref_im3);
% hold on; 
% plot(ref_pts3.selectStrongest(100));

%% Compute SURF features on reference image 4
ref_im_gray4 = csvread("ref4.csv");
ref_pts4 = detectSURFFeatures(ref_im_gray4);
[ref_features4, ref_validPts4] = extractFeatures(ref_im_gray4, ref_pts4);
% figure;
% imshow(ref_im4);
% hold on; 
% plot(ref_pts4.selectStrongest(100));
%% Compute SURF features on reference image 5
ref_im_gray5 = csvread("ref5.csv");
ref_pts5 = detectSURFFeatures(ref_im_gray5);
[ref_features5, ref_validPts5] = extractFeatures(ref_im_gray5, ref_pts5);
% figure;
% imshow(ref_im5);
% hold on; 
% plot(ref_pts5.selectStrongest(100));

%% Reads through a folder of images
% Get list of all BMP files in this directory
% DIR returns as a structure array.  You will need to use () and . to get
% the file names.

% folder = ['./preliminaryResult/', './rawData/'];
% for n=1:length(folder)
directory = './preliminaryResult/';
% disp(directory);
imagefiles = dir(strcat(directory, '*.png'));      
nfiles = length(imagefiles);    % Number of files found
storeName = {nfiles, 3};
numcount = 0;
% storeNameOnly = {};
%count = 0;
for fileNum=1:nfiles
   allInliers = [];
   currentfile = imagefiles(fileNum).name;
%    disp(currentfile);
   currentfilereturn = currentfile;
   currentfile = strcat(directory, currentfile);
   %currentimage = imread(strcat(directory, currentfile));
   %images{ii} = currentimage;
%  storeName{ii ,1} = currentfile;


%currentfile = '10croppedRed4.png';

    %% Compare with experimental footage ver 1 
    testImage1 = imread(currentfile);
    testImage_gray1 = rgb2gray(testImage1);
    t_pts1 = detectSURFFeatures(testImage_gray1);
    [t_features1, t_validPts1] = extractFeatures(testImage_gray1, t_pts1);
    % figure;
    % imshow(testImage1);
    % hold on; 
    % plot(t_pts1.selectStrongest(100));
    %% Compare with experimental footage ver 2 
    testImage2 = imread(currentfile);
    testImage_gray2 = rgb2gray(testImage2);
    t_pts2 = detectSURFFeatures(testImage_gray2);
    [t_features2, t_validPts2] = extractFeatures(testImage_gray2, t_pts2);
    % figure;
    % imshow(testImage2);
    % hold on; 
    % plot(t_pts2.selectStrongest(100));
    %% Compare with experimental footage ver 3 
    testImage3 = imread(currentfile);
    testImage_gray3 = rgb2gray(testImage3);
    t_pts3 = detectSURFFeatures(testImage_gray3);
    [t_features3, t_validPts3] = extractFeatures(testImage_gray3, t_pts3);
    % figure;
    % imshow(testImage3);
    % hold on; 
    % plot(t_pts3.selectStrongest(100));
    %% Compare with experimental footage ver 4 
    testImage4 = imread(currentfile);
    testImage_bi4 = rgb2gray(testImage4);
    t_pts4 = detectSURFFeatures(testImage_bi4);
    [t_features4, t_validPts4] = extractFeatures(testImage_bi4, t_pts4);
    % figure;
    % imshow(testImage4);
    % hold on; 
    % plot(t_pts4.selectStrongest(100));
    %% Compare with experimental footage ver 5 
    testImage5 = imread(currentfile);
    testImage_gray5 = rgb2gray(testImage5);
    t_pts5 = detectSURFFeatures(testImage_gray5);
    [t_features5, t_validPts5] = extractFeatures(testImage_gray5, t_pts5);
    % figure;
    % imshow(testImage5);
    % hold on; 
    % plot(t_pts5.selectStrongest(100));
    %% Keeps track of number of inliers
    scoreCount = 0;

    %% Match the features for reference image 1
    pairs = matchFeatures(ref_features1, t_features1);
    ref_matched1 = ref_validPts1(pairs(:,1)).Location;
    t_matched1 = t_validPts1(pairs(:,2)).Location;
    inlierPt1 = [];

    if ((size(t_matched1, 1) > 2) || (size(ref_matched1, 1) > 2))
%         figure, ax=axes;
%         leg = legend(ax, 'Matched points 1','Matched points 2');
%         leg.FontSize = 15;
%         showMatchedFeatures(testImage1, ref_im1, t_matched1, ref_matched1, 'montage',...
%         'Parent', ax);
%         disp('test 1 total num: ');
%         disp(size(ref_matched1, 1));
        try
            [tform,inlierPtsDistorted1,inlierPtsOriginal1] = ...
            estimateGeometricTransform(t_matched1,ref_matched1,'similarity');
            if ((size(inlierPtsDistorted1, 1) > 0) || (size(inlierPtsOriginal1, 1) > 0))
%                 figure;
%                 showMatchedFeatures(testImage1, ref_im1, inlierPtsDistorted1, inlierPtsOriginal1,...
%                 'montage');
                inlierPt1 = inlierPtsDistorted1;
%                 title('Showing match only with Inliers Ref1');
%                 disp('test 1 inlier num: ');
%                 disp(size(inlierPt1, 1));
                scoreCount = scoreCount + size(inlierPt1, 1);
                allInliers = [allInliers, inlierPt1];
            end
        catch
        end

    else 
    %     disp('test 1 total num: 0');
    end
    %% Match the features for reference image 2
    pairs2 = matchFeatures(ref_features2, t_features2);
    ref_matched2 = ref_validPts2.Location(pairs2(:,1));
    t_matched2 = t_validPts2.Location(pairs2(:,2));
    inlierPt2 = {};

    if (((size(t_matched2, 1) > 2) || (size(ref_matched2, 1) > 2)))
%         figure, bx=axes;
%         showMatchedFeatures(testImage2, ref_im2, t_matched2, ref_matched2, 'montage',...
%         'Parent', bx);
%         disp('test 2 total num: ');
%         disp(size(ref_matched2, 1));

       try
            [~,inlierPtsDistorted2,inlierPtsOriginal2] = ...
            estimateGeometricTransform(t_matched2,ref_matched2,'similarity');
            if ((size(inlierPtsDistorted2, 1) > 0) || (size(inlierPtsOriginal2, 1) > 0))
%                 figure;
%                 showMatchedFeatures(testImage2, ref_im2, inlierPtsDistorted2, inlierPtsOriginal2,...
%                 'montage');
                inlierPt2 = inlierPtsDistorted2;
%                 title('Showing match only with Inliers Ref2');
%                 disp('test 2 inlier num: ');
%                 disp(size(inlierPt2, 1));
                scoreCount = scoreCount + size(inlierPt2, 1);
                allInliers = [allInliers, inlierPt2];
            end
        catch
        end  

    else 
    %     disp('test 2 total num: 0');
    end

    %% Match the features for reference image 3
    pairs3 = matchFeatures(ref_features3, t_features3);
    ref_matched3 = ref_validPts3(pairs3(:,1)).Location;
    t_matched3 = t_validPts3(pairs3(:,2)).Location;
    inlierPt3 = {};
    if ((size(t_matched3, 1) > 2) || (size(ref_matched3, 1) > 2))
    %     figure, cx=axes;
    %     showMatchedFeatures(testImage3, ref_im3, t_matched3, ref_matched3, 'montage',...
    %     'Parent', cx);
    %     disp('test 3 total num: ');
    %     disp(size(ref_matched3, 1));

        try
            [tform,inlierPtsDistorted3,inlierPtsOriginal3] = ...
            estimateGeometricTransform(t_matched3,ref_matched3,'similarity'); 
            if ((size(inlierPtsDistorted3, 1) > 0) || (size(inlierPtsOriginal3, 1) > 0))
%                 figure;
%                 showMatchedFeatures(testImage3, ref_im3, inlierPtsDistorted3, inlierPtsOriginal3,...
%                 'montage');
                inlierPt3 = inlierPtsDistorted3;
    %             title('Showing match only with Inliers Ref3');

    %             disp('test 3 inlier num: ');
    %             disp(size(inlierPt3, 1));
                scoreCount = scoreCount + size(inlierPt3, 1);
                allInliers = [allInliers, inlierPt3];
            end
        catch
        end
    else 
        %disp('test 3 total num: 0');
    end
    %% Match the features for reference image 4
    pairs4 = matchFeatures(ref_features4, t_features4);
    ref_matched4 = ref_validPts4(pairs4(:,1)).Location;
    t_matched4 = t_validPts4(pairs4(:,2)).Location;
    inlierPt4 = {};
    if ((size(t_matched4, 1) > 2) || (size(ref_matched4, 1) > 2))
%         figure, cx=axes;
%         showMatchedFeatures(testImage3, ref_im3, t_matched3, ref_matched3, 'montage',...
%         'Parent', cx);
%         disp('test 3 total num: ');
%         disp(size(ref_matched3, 1));

        try
            [tform,inlierPtsDistorted4,inlierPtsOriginal4] = ...
            estimateGeometricTransform(t_matched4,ref_matched4,'similarity'); 
            if ((size(inlierPtsDistorted4, 1) > 0) || (size(inlierPtsOriginal4, 1) > 0))
%                 figure;
%                 showMatchedFeatures(testImage4, ref_im4, inlierPtsDistorted4, inlierPtsOriginal4,...
%                 'montage');
                inlierPt4 = inlierPtsDistorted4;
    %             title('Showing match only with Inliers Ref4');

    %             disp('test 4 inlier num: ');
    %             disp(size(inlierPt4, 1));
                scoreCount = scoreCount + size(inlierPt4, 1);
                allInliers = [allInliers, inlierPt4];
            end
        catch
        end
    else 
        %disp('test 4 total num: 0');

    end
     %% Match the features for reference image 5
    pairs5 = matchFeatures(ref_features5, t_features5);
    ref_matched5 = ref_validPts5(pairs5(:,1)).Location;
    t_matched5 = t_validPts5(pairs5(:,2)).Location;
    inlierPt5 = {};
    if ((size(t_matched5, 1) > 2) || (size(ref_matched5, 1) > 2))
    %     figure, cx=axes;
    %     showMatchedFeatures(testImage5, ref_im5, t_matched5, ref_matched5, 'montage',...
    %     'Parent', cx);
    %     disp('test 5 total num: ');
    %     disp(size(ref_matched5, 1));

        try
            [tform,inlierPtsDistorted5,inlierPtsOriginal5] = ...
            estimateGeometricTransform(t_matched5,ref_matched5,'similarity'); 
            if ((size(inlierPtsDistorted5, 1) > 0) || (size(inlierPtsOriginal5, 1) > 0))
%                 figure;
%                 showMatchedFeatures(testImage5, ref_im5, inlierPtsDistorted5, inlierPtsOriginal5,...
%                 'montage');
                inlierPt5 = inlierPtsDistorted5;
    %             title('Showing match only with Inliers Ref5');

    %             disp('test 5 inlier num: ');
    %             disp(size(inlierPt5, 1));
                scoreCount = scoreCount + size(inlierPt5, 1);
                allInliers = [allInliers, inlierPt5];
            end
        catch
        end
    else 
        %disp('test 5 total num: 0');
    end
    %% Displays in Command Window whether files contain bus stop or not
    if (scoreCount == 0)
    %     disp(currentfile);
    %     disp("No Bus Stop");
    %     storeName{ii, 2} = "No Bus Stop";
    %     storeName{ii, 3} = 0;
    end

    %% Outputs confidence level for each image 
    % 0 is low, 1 is medium, 2 is high 
    % cutoff is 3 for low based on testing 
    % 6 is currently arbitrary

    if (scoreCount > 0) 
    %     disp(currentfile);
    %     disp("Bus Stop Found");
        %storeName{ii, 2} = "Bus Stop Found";
      if (~contains(currentfile, 'full'))  
        numcount = numcount + 1;
        storeName{numcount,1} = currentfilereturn;
        if (scoreCount < 3) 
            storeName{numcount, 2} = 0;
            plot(allInliers(:,1),allInliers(:,2),'rx')
        elseif (scoreCount <= 6) 
            storeName{numcount, 2} = 1;
            plot(allInliers(:,1),allInliers(:,2),'rx')
        else
            storeName{numcount, 2} = 2;
            plot(allInliers(:,1),allInliers(:,2),'rx')
        end
      end


    %% Displays bounding boxes for images that come as full size (failed 
    %  shape and color test
       if (contains(currentfile, 'full'))  
%        if (directory == './preliminaryResult/')
%             disp("Check");
            if (scoreCount > 3) 
                allInliers = [];
                if (size(inlierPt1, 1) > 0) 
                    allInliers = [allInliers; inlierPt1];
                end
                if (size(inlierPt2, 1) > 0) 
                    allInliers = [allInliers; inlierPt2];
                end
                if (size(inlierPt3, 1) > 0) 
                    allInliers = [allInliers; inlierPt3];
                end
                if (size(inlierPt4, 1) > 0) 
                    allInliers = [allInliers; inlierPt4];
                end
                if (size(inlierPt5, 1) > 0) 
                    allInliers = [allInliers; inlierPt5];
                end
                minx = allInliers(1,1);
                maxx = minx;
                miny = allInliers(1,2);
                maxy = miny;
                for ii=1:size(allInliers, 1)
                    if (minx > allInliers(ii, 1))
                        minx = allInliers(ii, 1);
                    end
                    if (maxx < allInliers(ii, 1))
                        maxx = allInliers(ii, 1);
                    end
                    if (miny > allInliers(ii, 2))
                        miny = allInliers(ii, 2);
                    end
                    if (maxy < allInliers(ii, 2))
                        maxy = allInliers(ii, 2);
                    end
                end
%% Draw Bounding Boxes for SURF ONLY Images
                
                pic = imread(currentfile);
                fh = figure;
                imshow( pic, 'border', 'tight' )
                hold on;
%                     [X, Y, color] = size(testImage3);
%                     X = X * 0.0025;
%                     Y = Y * 0.005;
%                     width = (maxx - miny) * X;
%                     height = (maxy - miny)* Y;
%                     rectangle('Position', [minx - 20, miny - 40, width, height],'EdgeColor','r', 'LineWidth',3); %// draw rectangle on image
%                 plot(allInliers(:,1),allInliers(:,2),'rx')
                plot(allInliers(:,1),allInliers(:,2),'bo', 'MarkerSize',3, 'linewidth', 3)
                frm = getframe( fh ); %// get the image+rectangle
                imwrite( frm.cdata, "./finalResult/largeTest ("+fileNum+").PNG");
                hold off;
                close(fh);
                
            end
        end
    end    
end

save('./storeName.mat','storeName');


for i = 1:length(storeName)-1
    name = storeName{i,1};
    for j = 1:size(locations,2)
        
        if strcmp(name,locations(j).name)
            
            target = locations(j);
           IM = imread("./finalResult/largeTest ("+target.number+").PNG");
            
            
info = imfinfo("./finalResult/largeTest ("+target.number+").PNG");
if isfield(info,'Orientation')
   orient = info(1).Orientation;
   switch orient
     case 1
        %normal, leave the data alone
     case 2
        IM = IM(:,end:-1:1,:);         %right to left
     case 3
        IM = IM(end:-1:1,end:-1:1,:);  %180 degree rotation
     case 4
        IM = IM(end:-1:1,:,:);         %bottom to top
     case 5
        IM = permute(IM, [2 1 3]);     %counterclockwise and upside down
     case 6
        IM = rot90(IM,3);              %undo 90 degree by rotating 270
     case 7
        IM = rot90(IM(end:-1:1,:,:));  %undo counterclockwise and left/right
     case 8
        IM = rot90(IM);                %undo 270 rotation by rotating 90
       otherwise
        warning(sprintf('unknown orientation %g ignored\n', orient));
   end
 end
            pic = IM;
            fh = figure;
            imshow( pic, 'border', 'tight' )
            hold on;
            sumScore = target.level;
            sumScore = sumScore + storeName{i,2};
%             if (sumScore >=2) 
%                 rectangle('Position', target.rectangle,'EdgeColor','g','LineWidth',2); %// draw rectangle on image
%             end
            if target.level==2&& storeName{i,2}== 2
                rectangle('Position', target.rectangle,'EdgeColor','g','LineWidth',2); %// draw rectangle on image
            elseif target.level==1&& storeName{i,2}== 2
                rectangle('Position', target.rectangle,'EdgeColor','y','LineWidth',2); %// draw rectangle on image
            elseif target.level==0&& storeName{i,2}== 2
                 rectangle('Position', target.rectangle,'EdgeColor','b','LineWidth',2); %// draw rectangle on image
            elseif target.level==2&& storeName{i,2}== 1
                rectangle('Position', target.rectangle,'EdgeColor','m','LineWidth',2); %// draw rectangle on image
            elseif target.level==1&& storeName{i,2}== 1
                rectangle('Position', target.rectangle,'EdgeColor','r','LineWidth',2); %// draw rectangle on image
%             elseif target.level==0&& storeName{i,2}== 1
%                  rectangle('Position', target.rectangle,'EdgeColor','g','LineWidth',2); %// draw rectangle on image
            end
%             
            frm = getframe( fh ); %// get the image+rectangle
            imwrite( frm.cdata, "./finalResult/largeTest ("+target.number+").PNG");
            hold off;
            close(fh);
            break;
        end
    end
end

    for j = 1:size(locations,2)
        
        if locations(j).ishigh == 1
            target = locations(j);
           IM = imread("./finalResult/largeTest ("+target.number+").PNG");
            info = imfinfo("./finalResult/largeTest ("+target.number+").PNG");
            disp(target.number)
if isfield(info,'Orientation')
   orient = info(1).Orientation;
   switch orient
     case 1
        %normal, leave the data alone
     case 2
        IM = IM(:,end:-1:1,:);         %right to left
     case 3
        IM = IM(end:-1:1,end:-1:1,:);  %180 degree rotation
     case 4
        IM = IM(end:-1:1,:,:);         %bottom to top
     case 5
        IM = permute(IM, [2 1 3]);     %counterclockwise and upside down
     case 6
        IM = rot90(IM,3);              %undo 90 degree by rotating 270
     case 7
        IM = rot90(IM(end:-1:1,:,:));  %undo counterclockwise and left/right
     case 8
        IM = rot90(IM);                %undo 270 rotation by rotating 90
       otherwise
        warning(sprintf('unknown orientation %g ignored\n', orient));
   end
 end
            pic = IM;
             fh = figure;
            imshow( pic, 'border', 'tight' )
            hold on;
            
            rectangle('Position', target.rectangle,'EdgeColor','g'); %// draw rectangle on image
            
            frm = getframe( fh ); %// get the image+rectangle
            imwrite( frm.cdata, "./finalResult/largeTest ("+target.number+").PNG");
            hold off;
            close(fh);
            
        end
    end

