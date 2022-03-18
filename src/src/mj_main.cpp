#include "mj_sim.h"
#ifdef VISUAL
#include "mj_visual.h"
#endif
#include "mj_hw_interface.h"
#include "mj_ros.h"

#include <controller_manager/controller_manager.h>
#include <thread>

static MjSim mj_sim;
#ifdef VISUAL
static MjVisual mj_visual;
#endif

static int i = 0;

void load_model(int argc, char **argv)
{
    // check command-line arguments
    if (argc != 2)
    {
        mju_error("\n Usage:  model.xml\n");
    }

    char error[1000] = "Could not load binary model";
    // load and compile model
    m = mj_loadXML(argv[1], 0, error, 1000);
    if (!m)
    {
        mju_error_s("Could not load model file '%s'", argv[1]);
    }

    // make data
    d = mj_makeData(m);
}

#ifdef VISUAL
// keyboard callback
void keyboard(GLFWwindow *window, int key, int scancode, int act, int mods)
{
    if (act == GLFW_PRESS && key == GLFW_KEY_SPACE)
    {
        MjSim::add_data();
    }
    if (act == GLFW_PRESS && key == GLFW_KEY_KP_ADD && rtf_des < 4)
    {
        rtf_des *= 2;
        i = 0;
        MjSim::sim_start = d->time;
        MjRos::ros_start = ros::Time::now();
    }
    if (act == GLFW_PRESS && key == GLFW_KEY_KP_SUBTRACT && rtf_des > 1 / 4)
    {
        rtf_des /= 2;
        i = 0;
        MjSim::sim_start = d->time;
        MjRos::ros_start = ros::Time::now();
    }
}
#endif

void controller(const mjModel *m, mjData *d)
{
    mj_sim.controller();
}

void simulate()
{
    MjHWInterface mj_hw_interface;
    controller_manager::ControllerManager controller_manager(&mj_hw_interface);

    ros::AsyncSpinner spinner(3);
    spinner.start();
    ros::Time last_sim_time = MjRos::ros_start;
    while (ros::ok())
    {
        {
            ros::Time sim_time = (ros::Time)(MjRos::ros_start.toSec() + d->time);
            ros::Duration sim_period = sim_time - last_sim_time;

            mtx.lock();
            mj_step1(m, d);
            // check if we should update the controllers
            if (sim_period.toSec() >= 1 / 10000.) // Controller with 10kHz, start from 0.1s to avoid unstable
            {
                // store simulation time
                last_sim_time = sim_time;

                // update the robot simulation with the state of the mujoco model
                mj_hw_interface.read();

                // compute the controller commands
                controller_manager.update(sim_time, sim_period);
            }
            // update the mujoco model with the result of the controller
            mj_hw_interface.write();

            mj_step2(m, d);
            mtx.unlock();
        }

        // Change timestep when out of sync
        int num_step = mju_ceil(0.1 / m->opt.timestep);
        static std::deque<double> last_sim_time;
        static std::deque<double> last_ros_time;
        double diff;
        double ros_time;
        double sim_time = d->time - MjSim::sim_start;
        if (i == 0)
        {
            last_sim_time.clear();
            last_ros_time.clear();
        }
        do
        {
            ros_time = (ros::Time::now() - MjRos::ros_start).toSec();
            diff = ros_time - sim_time / rtf_des;
        } while (mju_abs(diff) < 1E-3);
        last_ros_time.push_front(ros_time);
        last_sim_time.push_front(sim_time);
        if (i == num_step)
        {
            double ros_time_diff = ros_time - last_ros_time.back();
            double sim_time_diff = sim_time - last_sim_time.back();
            rtf = sim_time_diff / ros_time_diff;
            last_ros_time.pop_back();
            last_sim_time.pop_back();
        }
        else
        {
            i++;
        }

        // m->opt.timestep *= 1 + mju_pow(mju_abs(diff), 2) * mju_sign(diff);
    }
}

int main(int argc, char **argv)
{
    ros::init(argc, argv, "mujoco_sim");
    ros::NodeHandle n;

    load_model(argc, argv);

    MjRos mj_ros;
    mj_ros.init();
    mj_sim.init();

#ifdef VISUAL
    mj_visual.init();
    glfwSetKeyCallback(mj_visual.window, keyboard);
#endif

    mjcb_control = controller;

    std::thread ros_thread(&MjRos::update, mj_ros);

    // start simulation thread
    std::thread sim_thread(simulate);

    mjtNum sim_step_start = d->time;
    while (ros::ok())
    {
#ifdef VISUAL
        if (mj_visual.is_window_closed())
        {
            break;
        }
#endif

        if (d->time - sim_step_start > 1.0 / 60.0)
        {
#ifdef VISUAL
            mj_visual.render(d->time - MjSim::sim_start, (ros::Time::now() - MjRos::ros_start).toSec());
            sim_step_start = d->time;
#endif
        }
    }
    ros::shutdown();

    ros_thread.join();
    sim_thread.join();

    // free MuJoCo model and data, deactivate
    mj_deleteData(d);
    mj_deleteModel(m);

    return 0;
}