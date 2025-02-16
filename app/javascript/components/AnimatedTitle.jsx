import React, { useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const AnimatedTitle = ( {authenticatePath} ) => {
    const { currentUser } = useAuth();
    const pathRefs = useRef([]);
    const dotRefs = useRef([]);
    const clocheRef = useRef(null);
    const welcomeLinkRef = useRef(null);
    const navigate = useNavigate();

    useEffect(() => {
        // Reset all paths, dots, and cloche
        pathRefs.current.forEach(path => {
            if (path) {
                path.style.strokeDasharray = `${path.getTotalLength()}`;
                path.style.strokeDashoffset = `${path.getTotalLength()}`;
            }
        });

        dotRefs.current.forEach(dot => {
            if (dot) {
                dot.style.opacity = '0';
            }
        });

        if (clocheRef.current) {
            clocheRef.current.style.opacity = '0';
        }

        if (welcomeLinkRef.current) {
            welcomeLinkRef.current.style.opacity = '0';
        }

        // Animate paths sequentially
        const animatePath = (index) => {
            return new Promise((resolve) => {
                if (index >= pathRefs.current.length) {
                    resolve();
                    return;
                }

                const path = pathRefs.current[index];
                if (path) {
                    path.style.transition = 'stroke-dashoffset .4s ease-in-out';
                    path.style.strokeDashoffset = '0';

                    const delay = index === 12 ? 800 : 250;
                    setTimeout(() => {
                        resolve(animatePath(index + 1));
                    }, delay);
                } else {
                    resolve(animatePath(index + 1));
                }
            });
        };

        // Start the sequential animation
        animatePath(0).then(() => {
            // Animate dots after all paths are done
            dotRefs.current.forEach((dot, index) => {
                if (dot) {
                    setTimeout(() => {
                        dot.style.transition = 'opacity 0.3s ease-in-out';
                        dot.style.opacity = '1';
                    }, index * 300);
                }
            });

            // Animate cloche last
            setTimeout(() => {
                if (clocheRef.current) {
                    clocheRef.current.style.transition = 'opacity 1.5s ease-in-out';
                    clocheRef.current.style.opacity = '1';
                    welcomeLinkRef.current.style.transition = 'opacity 1s ease-in-out';
                    welcomeLinkRef.current.style.opacity = '1';
                }
            }, dotRefs.current.length * 300 + 100);
        });
    }, []);

    // Handler for the welcome link
    const handleWelcomeClick = (e) => {
        e.preventDefault();
        const destination = currentUser ? '/pantry' : authenticatePath;

        // Ensure full page reload to trigger route change
        window.location.href = destination;
    };


    return (
        <div className="w-full min-h-screen flex flex-col justify-center items-center bg-black p-8 gap-8">
            {/* Cloche SVG */}
            <div ref={clocheRef} className="w-32 h-32">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 227.5 227.5">
                    <path className="fill-white"
                          d="M33.05,96.93s3.39-73.12,80.7-76.2c52.37,2.24,77.03,39.5,79.27,76.2-7.56.28-7.56,0-7.56,0,0,0-4.76-55.19-57.71-65.84,11.21,5.6,46.79,16.5,49.31,65.96-10.93-.12-144-.12-144-.12Z"/>
                    <path className="fill-white"
                          d="M4.19,100.29h217.12s4.2-.28,4.2,1.96-2.52,2.8-4.76,2.8-17.37.56-20.17,1.4-3.36,3.92-11.77,3.92H53.78c-8.83,0-18.49,1.68-22.97-1.68-3.92-3.16-11.21-3.16-25.49-3.16-3.08.08-3.04-3.04-3.04-3.04,0,0-.6-2.2,1.92-2.2Z"/>
                    <path className="fill-white"
                          d="M58.35,163.16l13.3,26.24,37.39-24.98s10.78-8.09,16-13.48c5.03-4.85,13.3-13.48,16.36-16.36s9.89-9.17,12.94-10.42,8.27-2.88,9.89-4.31,1.44-5.35-1.8-6.09-6.83-.38-9.53.88-5.57,1.26-17.79,10.24c-6.29,3.95-14.74,8.63-22.29,11.68-5.39,1.8-10.6,4.31-15.46,4.13s-8.63-2.34-13.66-12.94-9.17-15.28-14.74-14.38-5.39,2.7-5.21,3.6,4.85,5.75,5.93,8.09,2.52,7.01,1.62,13.84.36,10.32-.9,12.44-1.98,5-4.13,6.62-7.91,5.21-7.91,5.21Z"/>
                    <path className="fill-white"
                          d="M54.76,164.41l-24.98,11.5,19.05,36.67,23.9-14.2-17.97-33.97ZM60.01,198.09c-1.15-.32-1.82-1.51-1.5-2.66.32-1.15,1.51-1.82,2.66-1.5,1.15.32,1.82,1.51,1.5,2.66-.32,1.15-1.51,1.82-2.66,1.5Z"/>
                    <path className="fill-white"
                          d="M107.96,19.19h10.78s-1.08-3.95,4.13-8.09c.36-1.44-3.11-6.29-9.01-6.11s-9.86,3.95-9.68,5.39,4.6,4.9,3.77,8.81Z"/>
                </svg>
            </div>

            {/* Text SVG */}
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 501.35 113.38" className="w-3/4 h-auto max-w-4xl">
                {/* T */}
                <path
                    ref={el => pathRefs.current[0] = el}
                    d="M26.33,28.6c1.18,3.57,1.83,7.45.85,11.08s-3.89,6.91-7.6,7.46c-4.09.6-8.2-2.37-9.58-6.26s-.35-8.37,1.99-11.78s5.85-5.86,9.56-7.69c7.42-3.66,15.93-5.08,24.13-4.02,10.66,1.37,20.97,6.8,31.6,5.28,1.52-.22,3.08-.6,4.29-1.55s2-2.57,1.58-4.05"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[1] = el}
                    d="M68.76,23.55c-7.46,5.18-12.31,13.32-16.16,21.55-3.86,8.23-7,16.87-12.14,24.36s-12.77,13.89-21.8,14.95c-1.72.2-3.57.18-5.03-.74s-2.3-3.01-1.36-4.46"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* o */}
                <path
                    ref={el => pathRefs.current[2] = el}
                    d="M82.09,56.09c1.03-3.17-1.1-6.82-4.2-8.06s-6.76-.39-9.46,1.57-4.57,4.87-5.98,7.89c-1.37,2.96-2.36,6.09-2.93,9.3-.64,3.59-.45,7.96,2.56,10.02,1.61,1.11,3.75,1.26,5.64.76s3.57-1.61,5.07-2.86c4.37-3.64,7.52-8.72,8.86-14.25.28-1.16.27-2.75-.86-3.15-.7-.25-1.51.18-1.93.79s-.55,1.38-.68,2.12c-.39,2.37-.74,4.96.46,7.04,1.54,2.65,5.26,3.43,8.13,2.36s5.01-3.54,6.6-6.16c2.78-4.58,4.29-9.92,4.34-15.27"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* ni */}
                <path
                    ref={el => pathRefs.current[3] = el}
                    d="M89.02,75.29c3.69-8.68,8.76-16.77,14.97-23.87,1.38-1.58,2.89-3.16,4.84-3.93s4.47-.48,5.74,1.19c1.05,1.38.99,3.36.35,4.97s-1.78,2.97-2.83,4.36c-2.62,3.49-4.74,7.37-6.24,11.47-.51,1.38-.94,2.93-.38,4.29.72,1.72,2.88,2.47,4.71,2.13s3.38-1.54,4.77-2.79c4.86-4.39,8.64-9.98,10.89-16.13"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* g */}
                <path
                    ref={el => pathRefs.current[4] = el}
                    d="M134.07,47.11c-3.49,2.42-6.04,6-7.86,9.84s-2.95,7.96-4.08,12.05c-.62,2.26-1.11,5.06.63,6.65,1.15,1.05,2.95,1.12,4.38.53s2.58-1.72,3.58-2.91c3.19-3.76,5.43-8.21,8.02-12.4s5.7-8.27,10.02-10.65s10.09-2.68,13.94.4"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[5] = el}
                    d="M147.84,49.99c-5.32,3.96-9.15,9.88-10.58,16.36-.36,1.64-.57,3.36-.17,4.99s1.51,3.16,3.1,3.69c1.48.49,3.15.04,4.44-.83s2.3-2.09,3.27-3.32c7.61-9.61,14.47-19.81,20.48-30.5"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[6] = el}
                    d="M162.24,50.42l-11.75,29.87c-1.59,4.05-3.21,8.15-5.69,11.72s-5.96,6.64-10.16,7.78c-2.58.7-5.91.32-7.07-2.09-.73-1.51-.32-3.38.65-4.76s2.4-2.34,3.85-3.19c7.26-4.27,15.58-6.52,22.78-10.89,7.61-4.61,13.79-11.57,17.46-19.68"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* h */}
                <path
                    ref={el => pathRefs.current[7] = el}
                    d="M164.95,76.12c5.76-17.6,13.92-34.42,24.18-49.84,3.45-5.19,8.78-12.41,15.06-14.35,1.73-.53,3.92-.06,4.76,1.55,1.79,3.41-3.57,10.02-5.59,12.41-8.45,10-18.08,18.99-28.63,26.74"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[8] = el}
                    d="M165.22,74.84c4.1-10.14,11.06-19.12,19.87-25.61,2.03-1.49,4.89-2.86,6.89-1.32,1.28.99,1.59,2.85,1.2,4.43s-1.34,2.93-2.22,4.29c-2.63,4.08-4.71,8.52-6.18,13.15-.57,1.82-1.01,3.95.08,5.51,1.27,1.82,4.09,1.88,5.99.74s3.09-3.13,4.21-5.04c6.45-11.04,12.89-22.07,19.34-33.11"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* t */}
                <path
                    ref={el => pathRefs.current[9] = el}
                    d="M202.86,58.7c-1.87,3.4-3.16,7.11-3.8,10.93-.36,2.13-.35,4.7,1.37,6,1.59,1.2,3.88.71,5.65-.21,5.31-2.76,8.32-8.44,11-13.79"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[10] = el}
                    d="M201.05,47.99h16.25"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* Apostrophe */}
                <path
                    ref={el => pathRefs.current[11] = el}
                    d="M227.54,31.18c-.76,4.81-1.84,9.56-3.25,14.22"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* s */}
                <path
                    ref={el => pathRefs.current[12] = el}
                    d="M235.54,64.43c-.87-2.19-4.11-2.58-6.01-1.18s-2.63,3.9-2.76,6.26c-.08,1.54.06,3.16.91,4.45,1.36,2.08,4.09,2.73,6.57,2.93,1.75.14,3.55.14,5.19-.47,2.59-.95,4.48-3.3,5.43-5.88s1.07-5.4.99-8.15c-.09-3.16-.44-6.31-1.04-9.42-.42-2.18-.96-4.41-.6-6.6s1.91-4.38,4.12-4.65c.63-.08,1.33.02,1.78.47.83.82.37,2.33-.57,3.02s-2.16.83-3.29,1.1c-3.55.85-6.61,3.17-8.96,5.96s-4.08,6.04-5.74,9.29"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* S */}
                <path
                    ref={el => pathRefs.current[13] = el}
                    d="M328.59,16.46c-.27,1.63,1.84,3.08,3.27,2.24,1.38-1.15,1.51-3.37.6-4.91s-2.61-2.49-4.36-2.92c-5.76-1.43-12.29,2.74-13.42,8.56-1.04,5.36,1.94,10.56,4.33,15.46,3.17,6.5,5.48,13.53,5.64,20.76s-2.01,14.67-6.88,20.01c-5.65,6.18-14.22,8.88-22.54,9.73-6.08.62-12.62.27-17.67-3.16-5.28-3.58-8.1-10.25-7.66-16.62s3.89-12.33,8.76-16.46c4.87-4.13,11.06-6.51,17.37-7.47,3.69-.56,8.05-.4,10.39,2.51,1.8,2.25,1.78,5.56.59,8.19s-3.34,4.68-5.57,6.51c-3.09,2.52-6.51,4.77-10.39,5.72s-8.26.42-11.32-2.14"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* p */}
                <path
                    ref={el => pathRefs.current[14] = el}
                    d="M350.55,34.79c-8.02,4.98-13.34,13.36-17.11,22.02-3.77,8.66-6.26,17.83-10.17,26.42-3.92,8.59-9.55,16.82-17.81,21.39-3.62,2-7.9,3.25-11.9,2.2s-7.42-4.94-6.85-9.04"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[15] = el}
                    d="M333.33,58.15c1.92-4.13,5.41-7.51,9.59-9.31,2.21-.95,5.09-1.34,6.76.39,1.43,1.48,1.32,3.83.94,5.85-1.13,5.98-3.85,11.66-7.8,16.29-1.49,1.75-3.2,3.38-5.32,4.28s-4.69.97-6.6-.3-2.85-4.04-1.68-6.01"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* ec */}
                <path
                    ref={el => pathRefs.current[16] = el}
                    d="M343.87,73.16c5.74.9,11-3.51,14.19-8.37s5.27-10.52,9.37-14.64c2.47-2.48,6.59-4.26,9.35-2.1,2.35,1.84,2.23,5.53.91,8.2-2.23,4.51-7.38,7.39-12.38,6.94-1.13-.1-2.31-.39-3.09-1.2s-.98-2.27-.15-3.04c-.99,2.51-1.99,5.06-2.16,7.75s.61,5.58,2.67,7.32c2.55,2.16,6.45,2.01,9.46.57,5.35-2.56,8.34-8.25,11.03-13.54s5.83-10.94,11.29-13.27c2.6-1.11,6.17-1.05,7.66,1.35,1.07,1.72.64,3.96.02,5.89-.44,1.35-1.02,2.76-2.17,3.59s-3.04.78-3.77-.44c-.69-1.16.04-2.74,1.18-3.46s2.56-.79,3.91-.84"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* i */}
                <path
                    ref={el => pathRefs.current[17] = el}
                    d="M390.88,49.38c-3.33,4.15-5.93,8.88-7.64,13.91-1.13,3.32-1.81,7.21.08,10.16,2.07,3.22,6.63,4.08,10.26,2.87s6.49-4.02,8.97-6.92c5.11-5.98,9.28-12.76,12.29-20.03"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* a */}
                <path
                    ref={el => pathRefs.current[18] = el}
                    d="M409.09,60.89c-1.99,2.62-4.08,5.48-4.14,8.78s3.01,6.79,6.15,5.81c1.53-.47,2.6-1.81,3.57-3.08,3.31-4.35,6.52-8.77,9.63-13.25,2.85-4.11,5.76-8.42,10.07-10.96s10.48-2.71,13.81,1.02"
                    className="stroke-white fill-none"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                <path
                    ref={el => pathRefs.current[19] = el}
                    d="M428.37,53.63c-3.38,4.77-5.74,10.27-6.85,16.01-.28,1.45-.45,3.07.35,4.3.9,1.37,2.79,1.82,4.39,1.45s2.97-1.38,4.24-2.42c6.22-5.11,11.33-11.55,14.9-18.77"
                    className="fill-none stroke-white"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* l */}
                <path
                    ref={el => pathRefs.current[20] = el}
                    d="M443.97,55.17c-3.31,3.59-5.69,8.04-6.84,12.79-.73,3-.6,6.86,2.12,8.32,1.53.82,3.47.54,4.99-.3s2.69-2.19,3.77-3.56c7.35-9.27,11.78-20.45,17.07-31.03s11.9-21.08,22.01-27.23c1.02-.62,2.1-1.2,3.29-1.3s2.5.39,3.03,1.45c.54,1.08.16,2.38-.3,3.51-3.92,9.69-12.21,16.79-20.06,23.69s-15.87,14.47-18.91,24.47c-.74,2.44-1.1,5.29.38,7.36,1.15,1.61,3.25,2.38,5.23,2.28s3.85-.99,5.47-2.13c3.94-2.78,6.64-7.27,7.24-12.06"
                    className="fill-none stroke-white"
                    strokeWidth="4"
                    strokeLinecap="round"
                />

                {/* Dots */}
                <circle
                    ref={el => dotRefs.current[0] = el}
                    cx="135.69"
                    cy="38.25"
                    r="3.47"
                    className="fill-white"
                />
                <circle
                    ref={el => dotRefs.current[1] = el}
                    cx="419.6"
                    cy="38.25"
                    r="3.47"
                    className="fill-white"
                />
            </svg>

            {/* Welcome Link */}
            <div
                ref={welcomeLinkRef}
                className="mt-8 opacity-0"
            >
                <button
                    onClick={handleWelcomeClick}
                    className="text-white hover:text-gray-300 text-lg font-medium flex items-center transition-colors duration-300"
                >
                    Welcome <span className="ml-1"></span>
                </button>
            </div>
        </div>
    );
};

export default AnimatedTitle;