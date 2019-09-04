# Unity3DSmoothShadowMap
传统的ShadowMap在明暗边缘处都会有很难看的锯齿，因此一般得到的结果会比较难看，常规的解决办法都会在使用ShadowMap渲染阴影的时候通过背面剔除把这种缺陷隐藏掉，最后剩下一个影子。但是这样一来，自阴影就会丢失，因而传统的做法又会通过局部光照来重新为这个物体添加上部分自阴影，也就是咱们常见的Phone光照模型、Blinn-Phone光照模型。而本文决定通过文献[1]的一个平滑方法把ShadowMap在明暗边缘处的锯齿消除，并和光照模型求并，最后得到了一个包含丰富平滑自阴影效果。  

理论原理：[点击这里](https://www.cnblogs.com/lht666/p/11454296.html)  

#参考文献  
Silhouette Smoothing for Real-time Rendering of Mesh Surfaces  
基于GPU的网格模型平滑阴影的实时绘制  
三角网格模型平滑阴影的实时绘制  
