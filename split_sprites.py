#!/usr/bin/env python3
"""
Sprite Sheet 拆分工具
自动将合在一起的图片拆分成单个文件
"""

from PIL import Image
import os
from collections import defaultdict

def find_connected_regions(img):
    """找出所有连通区域"""
    img_data = img.convert('RGBA')
    width, height = img.size
    pixels = img_data.load()
    
    visited = set()
    regions = []
    
    def flood_fill(start_x, start_y):
        """洪水填充找出连通区域"""
        stack = [(start_x, start_y)]
        min_x, max_x = start_x, start_x
        min_y, max_y = start_y, start_y
        pixels_found = []
        
        while stack:
            x, y = stack.pop()
            if (x, y) in visited:
                continue
            if x < 0 or x >= width or y < 0 or y >= height:
                continue
            if pixels[x, y][3] == 0:  # 透明像素
                continue
                
            visited.add((x, y))
            pixels_found.append((x, y))
            min_x = min(min_x, x)
            max_x = max(max_x, x)
            min_y = min(min_y, y)
            max_y = max(max_y, y)
            
            # 四个方向
            stack.append((x + 1, y))
            stack.append((x - 1, y))
            stack.append((x, y + 1))
            stack.append((x, y - 1))
        
        return (min_x, min_y, max_x + 1, max_y + 1), pixels_found
    
    for y in range(height):
        for x in range(width):
            if (x, y) not in visited and pixels[x, y][3] > 0:
                bbox, _ = flood_fill(x, y)
                regions.append(bbox)
    
    return regions

def split_image_vertical(input_path, output_dir, item_height=32, padding=2):
    """垂直排列的文字切片"""
    os.makedirs(output_dir, exist_ok=True)
    
    img = Image.open(input_path)
    base_name = os.path.splitext(os.path.basename(input_path))[0]
    
    print(f"\n📸 处理: {input_path}")
    
    width, height = img.size
    num_items = height // item_height
    
    for i in range(num_items):
        y = i * item_height
        cropped = img.crop((0, y - padding, width, y + item_height + padding))
        
        # 检查是否全透明
        if cropped.convert('RGBA').getdata()[3] == 0:
            continue
            
        output_name = f"{base_name}_text_{i:03d}.png"
        output_path = os.path.join(output_dir, output_name)
        cropped.save(output_path, 'PNG')
        print(f"   ✓ {output_name}")

def split_image(input_path, output_dir, padding=2):
    """拆分图片为单独的文件"""
    os.makedirs(output_dir, exist_ok=True)
    
    img = Image.open(input_path)
    base_name = os.path.splitext(os.path.basename(input_path))[0]
    
    # image_001.png 用垂直切割
    if "image_001" in base_name:
        split_image_vertical(input_path, output_dir)
        return
    
    # 其他图片用连通区域检测
    regions = find_connected_regions(img)
    
    print(f"\n📸 处理: {input_path}")
    print(f"   找到 {len(regions)} 个独立元素:")
    
    for i, (x1, y1, x2, y2) in enumerate(sorted(regions, key=lambda r: (r[1], r[0]))):
        # 添加内边距
        x1_pad = max(0, x1 - padding)
        y1_pad = max(0, y1 - padding)
        x2_pad = min(img.width, x2 + padding)
        y2_pad = min(img.height, y2 + padding)
        
        cropped = img.crop((x1_pad, y1_pad, x2_pad, y2_pad))
        output_name = f"{base_name}_{i:03d}.png"
        output_path = os.path.join(output_dir, output_name)
        
        cropped.save(output_path, 'PNG')
        print(f"   ✓ {output_name} ({x2_pad - x1_pad}x{y2_pad - y1_pad}px)")

def main():
    # 配置路径
    project_dir = "/Users/guojiong/Desktop/0.1编程项目/【合集】游戏/chui_adventure"
    images_dir = os.path.join(project_dir, "assets", "images")
    output_dir = os.path.join(project_dir, "assets", "images", "split")
    
    # 要拆分的图片列表
    images_to_split = [
        "image_001.png",   # UI文字
        "image_006.webp",  # UI图标
    ]
    
    print("🎮 开始拆分 Sprite Sheet...")
    print(f"   输出目录: {output_dir}\n")
    
    for img_name in images_to_split:
        input_path = os.path.join(images_dir, img_name)
        if os.path.exists(input_path):
            split_image(input_path, output_dir)
        else:
            print(f"⚠️  文件不存在: {input_path}")
    
    print(f"\n✅ 完成！拆分后的文件保存在: {output_dir}")
    print("\n拆分出的文件可以直接拖入Godot使用！")

if __name__ == "__main__":
    main()
