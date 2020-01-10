#include <iostream>
#include <string>
#include <sstream>
#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>

extern "C" void mandelbrot(unsigned char *pixel, int height, int width, double x, double y, double delta);
using namespace std;
int main()
{

    unsigned int width, height;
    double x = -1.5;
    double y = -1.5;
    cout<<"Put height of window"<<endl;
    cin>> height;
    cout<<"Put width of window"<<endl;
    cin>> width;

    double delta = 2*abs(x)/width;
    sf::RenderWindow window(sf::VideoMode(width, height, 32), "Mandelbrot",sf::Style::Default);
    sf::Uint8 *pixels = new unsigned char[width * height * 4];
    sf::Image image;
    sf::Texture texture;
    sf::Sprite sprite;
    while (window.isOpen()){
        sf::Event event;
        while (window.pollEvent(event)){
            if (event.type == sf::Event::Closed){
               window.close();
            }
            if (event.type == sf::Event::KeyPressed){
                if(event.key.code == sf::Keyboard::W){
                    x += 0.1*x;
                    y += 0.1*y;    
                    delta = 2*abs(x)/width;
                }else if(event.key.code == sf::Keyboard::Z){
                    x -= 0.1*x;
                    y -= 0.1*y; 
                    delta = 2*abs(x)/width;
                }else if(event.key.code == sf::Keyboard::Right){
                    x += 0.1*x;
                }else if(event.key.code == sf::Keyboard::Left){
                    x -= 0.1*x;
                }else if(event.key.code == sf::Keyboard::Down){
                    y -= 0.1*y; 
                }else if(event.key.code == sf::Keyboard::Up){
                    y += 0.1*y; 
                }
            }   
        }  
        mandelbrot(pixels, height, width, x, y, delta);
        image.create(width,height,pixels);
        texture.create(width,height);
        texture.update(image);
        sprite.setTexture(texture);
        window.clear();
        window.draw(sprite);
        window.display();
   }
    return 0;
}
