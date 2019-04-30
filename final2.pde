import g4p_controls.*;
GCustomSlider sdr;

int nx=450;
int ny=450;
int size = 2;
int pointNum=10000;
int iN=5; 

int expansion_candidates = 8;
int selection_size=100;
boolean reversed=true;
boolean include_original = false;

int tick = 0;
color[][] imgpixels=new int[ny][nx];
color[][] originalpixels=new int[ny][nx];
int[][][] result=new int[ny][nx][3];
PImage img;
ArrayList<Integer[]> candidates;
int pixels_placed;

boolean begin=false;

void setup() {
  size(900, 900);
  
  sdr = new GCustomSlider(this, 24, 24, 876, 24, null);
  // show          opaque  ticks value limits
  sdr.setShowDecor(false, false, false, false);
  sdr.setLimits(10000, 1000, nx*ny);
  
  
  
  pixelDensity(1);
  img=loadImage("./"+iN+".jpg");
  img.loadPixels();
  loadPixels();
  
  long THE_SEED=floor(random(9999999));
  randomSeed(THE_SEED);
  noStroke();
  int ir=0,ig=0,ib=0;
  for (int j=0;j<ny;j++){
    for(int i=0;i<nx;i++){
      int loc=(i+j*img.width);
        imgpixels[j][i]=img.pixels[loc];
        ir+=red(imgpixels[j][i]);
        ig+=green(imgpixels[j][i]);
        ib+=blue(imgpixels[j][i]);
        originalpixels[j][i]=img.pixels[loc];
        result[j][i][0]=-1;
        result[j][i][1]=-1;
        result[j][i][2]=-1;
    }
  }
  background(ir/(nx*ny),ig/(nx*ny),ib/(nx*ny));
}
void draw() {
  if(begin){
     if(pixels_placed<pointNum){
       try{
         placePixels(100);
       }catch(Exception e){
         checkhole();
         begin=false;
       }
     }else{
       checkhole();
       begin=false;
     }
  }
}

void drawImage(color[][] image) {
 for (int i=0;i<image.length;i++){
    for(int j=0;j<image[0].length;j++){
      drawPixel(i,j,image[i][j]);
    }
  }
  }
void drawPixel(int pos0,int pos1, color col) {
    fill(col);
    rect(size*pos1,size*pos0,size,size);
}
void checkhole(){
  for (int j=1;j<ny-1;j++){
    for(int i=1;i<nx-1;i++){
      if (result[i-1][j][1]!=-1 && result[i+1][j][1]!=-1 && result[i][j][1]==-1){
        result[i][j][0]=result[i-1][j][0];
        result[i][j][1]=result[i-1][j][1];
        result[i][j][2]=result[i-1][j][2];
        drawPixel(i,j,color(result[i][j][0],result[i][j][1],result[i][j][2]));
      }
      if (result[i][j-1][1]!=-1 && result[i][j+1][1]!=-1 && result[i][j][1]==-1){
        result[i][j][0]=result[i][j-1][0];
        result[i][j][1]=result[i][j-1][1];
        result[i][j][2]=result[i][j-1][2];
        drawPixel(i,j,color(result[i][j][0],result[i][j][1],result[i][j][2]));
      }
    }
  }
}
  
void placePixels(int n){
  for (int i=0;i<n;i++){
    Integer[] result_pos=getNearest(Math.floor(nx/2),Math.floor(ny/2),candidates,reversed);
    color ori= getSurroundingColor(result_pos);
    int[] cands = getRandoms(selection_size, pixels_placed, nx*ny);
    int[] bi = findBestMatch(ori, cands);
    
    candidates = expandNeighborhood(candidates, result_pos);
    
    color pixel_to_swap=imgpixels[bi[0]][bi[1]];
    
    int row=(int)Math.floor(pixels_placed/nx);
    int col=pixels_placed%nx;
    imgpixels[bi[0]][bi[1]]=imgpixels[row][col];
    result[result_pos[0]][result_pos[1]][0]=(int)red(pixel_to_swap);
    result[result_pos[0]][result_pos[1]][1]=(int)green(pixel_to_swap);
    result[result_pos[0]][result_pos[1]][2]=(int)blue(pixel_to_swap);
    
    drawPixel(result_pos[0],result_pos[1],pixel_to_swap);
    pixels_placed++;
  }
  //checkhole();
} 


int[] findBestMatch(color origin, int[] candidates) {
    int[] best_idx = new int[2];
    double best_val = 1e10;
    for (int i = 0; i < candidates.length; i++) {
      int yy = floor(candidates[i] / nx);
      int xx = candidates[i] % nx;
      double val = compareCols(origin, imgpixels[yy][xx]);

      if (val < best_val) {
        best_val = val;
        best_idx[0]=yy;
        best_idx[1]=xx;
      }
    }
    return best_idx;
}
  
double compareCols(color a, color b) {
  float sr=red(a)-red(b);
  float sb=blue(a)-blue(b);
  float sg=green(a)-green(b);
  return sqrt(pow(sr, 2) + pow(sg, 2) + pow(sb, 2));
}
int[] getRandoms(int n, int from, int to) {
  int[] arr=new int[n];
  for(int i=0;i<n;i++){
    int rand = floor(random(from,to));
    arr[i]=rand;
  }
  return arr;
}

Integer[] getNearest(double q1, double q2,ArrayList<Integer[]> rs, boolean reverse){
  int closest=(int)(reverse?0:1e10);
  Integer[] closest_item = new Integer[3];
  int sign=reverse?-1:1;
  
  int[] selection=getRandoms(expansion_candidates, 0, rs.size() - 1);
  //if (rs.size() - 1<=0){
  //  println(pixels_placed);
  //  println(expansion_candidates);
  //}
  for (int r:selection){
    //println( rs.get(r)[0]);
    //println( rs.get(r)[1]);
    //println( rs.get(r)[2]);
    Integer dist = rs.get(r)[2];
    if (sign*dist<sign*closest){
      closest_item=rs.get(r);
      closest=dist;
    }
  }
  //println("-------------");
  //println(closest_item[0]);
  //println(closest_item[1]);
  //println(closest_item[2]);
  //println("-------------");
  return closest_item;
}
ArrayList<Integer[]> getAdjacentIndices(Integer[] q,boolean include_diago){
  ArrayList<Integer[]> indexs=new ArrayList<Integer[]>();
  
  //println("q:");
  // println(q[0]);
  //  println(q[1]);
  //  println(q[2]);
  //  println("------");
  if(q[0]<nx-1){ 
    Integer[] tmpQ=new Integer[3];
    tmpQ[0]=q[0]+1;tmpQ[1]=q[1];tmpQ[2]=q[2]+1;
    indexs.add(tmpQ);
  }
  if(q[0]<ny-1){ 
    Integer[] tmpQ=new Integer[3];
    tmpQ[0]=q[0];tmpQ[1]=q[1]+1;tmpQ[2]=q[2]+1;
    indexs.add(tmpQ);
  }
  if(q[0]>0){ 
    Integer[] tmpQ=new Integer[3];
    tmpQ[0]=q[0]-1;tmpQ[1]=q[1];tmpQ[2]=q[2]+1;
    indexs.add(tmpQ);
  }
  if(q[1]>0){ 
    Integer[] tmpQ=new Integer[3];
    tmpQ[0]=q[0];tmpQ[1]=q[1]-1;tmpQ[2]=q[2]+1;
    indexs.add(tmpQ);
  }
  if(include_diago){
    if(q[0]<nx-1){
      if(q[1]<ny-1){
        Integer[] tmpQ=new Integer[3];
        tmpQ[0]=q[0]+1;tmpQ[1]=q[1]+1;tmpQ[2]=q[2]+1;
        indexs.add(tmpQ);
      }
      if(q[1]>0){
        Integer[] tmpQ=new Integer[3];
        tmpQ[0]=q[0]+1;tmpQ[1]=q[1]-1;tmpQ[2]=q[2]+1;
        indexs.add(tmpQ);
      }
    }
    if(q[0]>0){
      if(q[1]<ny-1){ 
        Integer[] tmpQ=new Integer[3];
        tmpQ[0]=q[0]-1;tmpQ[1]=q[1]+1;tmpQ[2]=q[2]+1;
        indexs.add(tmpQ);
      }
      if(q[1]>0){
        Integer[] tmpQ=new Integer[3];
        tmpQ[0]=q[0]-1;tmpQ[1]=q[1]-1;tmpQ[2]=q[2]+1;
        indexs.add(tmpQ);
      }
    }
  }
  //for (Integer[] i: indexs){
  //  println(i[0]);
  //  println(i[1]);
  //  println(i[2]);
  //}
  return indexs;
}
color meanColor(ArrayList<Integer[]> clr){
  Integer r=0,g=0,b=0;
  for (Integer[]c:clr){
    r=r+c[0];
    g=g+c[1];
    b=b+c[2];
  }
  return color(r/clr.size(),g/clr.size(),b/clr.size());
}


color getSurroundingColor(Integer[] q){
  ArrayList<Integer[]> adjacrntIndixs=getAdjacentIndices(q, true);
  ArrayList<Integer[]> adj=new ArrayList<Integer[]>();
  for (Integer[]i:adjacrntIndixs){
      if (result[i[0]][i[1]][0]!=-1){
        Integer[] clr=new Integer[3];
        clr[0]=result[i[0]][i[1]][0];
        clr[1]=result[i[0]][i[1]][1];
        clr[2]=result[i[0]][i[1]][2];
        adj.add(clr);
      }
    }

  return meanColor(adj);
}
ArrayList<Integer[]> expandNeighborhood(ArrayList<Integer[]> neighborhood, Integer[] next) {
    boolean includeNext=neighborhood.contains(next);
    if (!includeNext) {
      println("ERROR");
      return neighborhood;
    }
    ArrayList<Integer[]> adjacrntIndixs=getAdjacentIndices(next, true);
    ArrayList<Integer[]> expansion=new ArrayList<Integer[]>();
    for (Integer[]i:adjacrntIndixs){
      if (result[i[0]][i[1]][1]<0){
        expansion.add(i);
      }
    }
    int next_index = neighborhood.indexOf(next);
    neighborhood.remove(next_index);
    neighborhood.removeAll(expansion);
    neighborhood.addAll(expansion);
    return neighborhood; // return union
}
void mouseClicked(){
  if (mouseX*mouseY!=0 && !begin){
    if (mouseButton == LEFT){
        Integer[] centre = new Integer[3];
        centre[0]=min(max(mouseY/2,1),nx-1);
        centre[1]=min(max(mouseX/2,1),ny-1);
        centre[2]=0;
         color start=imgpixels[(int)Math.floor(Math.random() * nx)][(int)Math.floor(Math.random()*ny)];
        
        result[centre[0]][centre[1]][0]=(int)red(start);
        result[centre[0]][centre[1]][1]=(int)green(start);
        result[centre[0]][centre[1]][2]=(int)blue(start);
        
        drawPixel(centre[0],centre[1],start);
        ArrayList<Integer[]> indexs=new ArrayList<Integer[]>();
        indexs.add(centre);
        candidates = expandNeighborhood(indexs, centre);
        
        pixels_placed=0;
        begin=true;
    }else{
      iN++;
      if(iN==6) iN=1; 
      background(0);
      img=loadImage("./"+iN+".jpg");
      img.loadPixels();
      loadPixels();
      
      long THE_SEED=floor(random(9999999));
      randomSeed(THE_SEED);
      noStroke();
      int ir=0,ig=0,ib=0;
      for (int j=0;j<ny;j++){
        for(int i=0;i<nx;i++){
        int loc=(i+j*img.width);
        imgpixels[j][i]=img.pixels[loc];
        ir+=red(imgpixels[j][i]);
        ig+=green(imgpixels[j][i]);
        ib+=blue(imgpixels[j][i]);
        originalpixels[j][i]=img.pixels[loc];
        result[j][i][0]=-1;
        result[j][i][1]=-1;
        result[j][i][2]=-1;
      }
  }
  background(ir/(nx*ny),ig/(nx*ny),ib/(nx*ny));
      
    }
}
}
void handleSliderEvents(GValueControl slider, GEvent event) {
  if (!begin){
  pointNum=slider.getValueI();
  println(pointNum);
  }
}
